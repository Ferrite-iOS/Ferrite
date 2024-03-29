//
//  RealDebridWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/7/22.
//

import Foundation

public class RealDebrid {
    let jsonDecoder = JSONDecoder()

    let baseAuthUrl = "https://api.real-debrid.com/oauth/v2"
    let baseApiUrl = "https://api.real-debrid.com/rest/1.0"
    let openSourceClientId = "X245A4XAIBGVM"

    var authTask: Task<Void, Error>?

    @MainActor
    func setUserDefaultsValue(_ value: Any, forKey: String) {
        UserDefaults.standard.set(value, forKey: forKey)
    }

    @MainActor
    func removeUserDefaultsValue(forKey: String) {
        UserDefaults.standard.removeObject(forKey: forKey)
    }

    // Fetches the device code from RD
    public func getVerificationInfo() async throws -> DeviceCodeResponse {
        var urlComponents = URLComponents(string: "\(baseAuthUrl)/device/code")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: openSourceClientId),
            URLQueryItem(name: "new_credentials", value: "yes")
        ]

        guard let url = urlComponents.url else {
            throw RDError.InvalidUrl
        }

        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let rawResponse = try jsonDecoder.decode(DeviceCodeResponse.self, from: data)
            return rawResponse
        } catch {
            print("Couldn't get the new client creds!")
            throw RDError.AuthQuery(description: error.localizedDescription)
        }
    }

    // Fetches the user's client ID and secret
    public func getDeviceCredentials(deviceCode: String) async throws {
        var urlComponents = URLComponents(string: "\(baseAuthUrl)/device/credentials")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: openSourceClientId),
            URLQueryItem(name: "code", value: deviceCode)
        ]

        guard let url = urlComponents.url else {
            throw RDError.InvalidUrl
        }

        let request = URLRequest(url: url)

        // Timer to poll RD API for credentials
        authTask = Task {
            var count = 0

            while count < 12 {
                if Task.isCancelled {
                    throw RDError.AuthQuery(description: "Token request cancelled.")
                }

                let (data, _) = try await URLSession.shared.data(for: request)

                // We don't care if this fails
                let rawResponse = try? self.jsonDecoder.decode(DeviceCredentialsResponse.self, from: data)

                // If there's a client ID from the response, end the task successfully
                if let clientId = rawResponse?.clientID, let clientSecret = rawResponse?.clientSecret {
                    await setUserDefaultsValue(clientId, forKey: "RealDebrid.ClientId")
                    FerriteKeychain.shared.set(clientSecret, forKey: "RealDebrid.ClientSecret")

                    try await getTokens(deviceCode: deviceCode)

                    return
                } else {
                    try await Task.sleep(seconds: 5)
                    count += 1
                }
            }

            throw RDError.AuthQuery(description: "Could not fetch the client ID and secret in time. Try logging in again.")
        }

        if case let .failure(error) = await authTask?.result {
            throw error
        }
    }

    // Fetch all tokens for the user and store in FerriteKeychain.shared
    public func getTokens(deviceCode: String) async throws {
        guard let clientId = UserDefaults.standard.string(forKey: "RealDebrid.ClientId") else {
            throw RDError.EmptyData
        }

        guard let clientSecret = FerriteKeychain.shared.get("RealDebrid.ClientSecret") else {
            throw RDError.EmptyData
        }

        var request = URLRequest(url: URL(string: "\(baseAuthUrl)/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: deviceCode),
            URLQueryItem(name: "grant_type", value: "http://oauth.net/grant_type/device/1.0")
        ]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        let rawResponse = try jsonDecoder.decode(TokenResponse.self, from: data)

        FerriteKeychain.shared.set(rawResponse.accessToken, forKey: "RealDebrid.AccessToken")
        FerriteKeychain.shared.set(rawResponse.refreshToken, forKey: "RealDebrid.RefreshToken")

        let accessTimestamp = Date().timeIntervalSince1970 + Double(rawResponse.expiresIn)
        await setUserDefaultsValue(accessTimestamp, forKey: "RealDebrid.AccessTokenStamp")
    }

    public func fetchToken() async -> String? {
        let accessTokenStamp = UserDefaults.standard.double(forKey: "RealDebrid.AccessTokenStamp")

        if Date().timeIntervalSince1970 > accessTokenStamp {
            do {
                if let refreshToken = FerriteKeychain.shared.get("RealDebrid.RefreshToken") {
                    try await getTokens(deviceCode: refreshToken)
                }
            } catch {
                print(error)
                return nil
            }
        }

        return FerriteKeychain.shared.get("RealDebrid.AccessToken")
    }

    // Adds a manual API key instead of web auth
    // Clear out existing refresh tokens and timestamps
    public func setApiKey(_ key: String) -> Bool {
        FerriteKeychain.shared.set(key, forKey: "RealDebrid.AccessToken")
        FerriteKeychain.shared.delete("RealDebrid.RefreshToken")
        FerriteKeychain.shared.delete("RealDebrid.AccessTokenStamp")

        UserDefaults.standard.set(true, forKey: "RealDebrid.UseManualKey")

        return FerriteKeychain.shared.get("RealDebrid.AccessToken") == key
    }

    public func deleteTokens() async throws {
        FerriteKeychain.shared.delete("RealDebrid.RefreshToken")
        FerriteKeychain.shared.delete("RealDebrid.ClientSecret")
        await removeUserDefaultsValue(forKey: "RealDebrid.ClientId")
        await removeUserDefaultsValue(forKey: "RealDebrid.AccessTokenStamp")

        // Run the request, doesn't matter if it fails
        if let token = FerriteKeychain.shared.get("RealDebrid.AccessToken") {
            var request = URLRequest(url: URL(string: "\(baseApiUrl)/disable_access_token")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)

            FerriteKeychain.shared.delete("RealDebrid.AccessToken")
            await removeUserDefaultsValue(forKey: "RealDebrid.UseManualKey")
        }
    }

    // Wrapper request function which matches the responses and returns data
    @discardableResult private func performRequest(request: inout URLRequest, requestName: String) async throws -> Data {
        guard let token = await fetchToken() else {
            throw RDError.InvalidToken
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw RDError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode >= 200, response.statusCode <= 299 {
            return data
        } else if response.statusCode == 401 {
            try await deleteTokens()
            throw RDError.FailedRequest(description: "The request \(requestName) failed because you were unauthorized. Please relogin to RealDebrid in Settings.")
        } else {
            throw RDError.FailedRequest(description: "The request \(requestName) failed with status code \(response.statusCode).")
        }
    }

    // Checks if the magnet is streamable on RD
    // Currently does not work for batch links
    public func instantAvailability(magnets: [Magnet]) async throws -> [IA] {
        var availableHashes: [RealDebrid.IA] = []
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/instantAvailability/\(magnets.compactMap(\.hash).joined(separator: "/"))")!)

        let data = try await performRequest(request: &request, requestName: #function)

        // Does not account for torrent packs at the moment
        let rawResponseDict = try jsonDecoder.decode([String: InstantAvailabilityResponse].self, from: data)

        for (hash, response) in rawResponseDict {
            guard let data = response.data else {
                continue
            }

            if data.rd.isEmpty {
                continue
            }

            // Is this a batch
            if data.rd.count > 1 || data.rd[0].count > 1 {
                // Batch array
                let batches = data.rd.map { fileDict in
                    let batchFiles: [RealDebrid.IABatchFile] = fileDict.map { key, value in
                        // Force unwrapped ID. Is safe because ID is guaranteed on a successful response
                        RealDebrid.IABatchFile(id: Int(key)!, fileName: value.filename)
                    }.sorted(by: { $0.id < $1.id })

                    return RealDebrid.IABatch(files: batchFiles)
                }

                // RD files array
                // Possibly sort this in the future, but not sure how at the moment
                var files: [RealDebrid.IAFile] = []

                for index in batches.indices {
                    let batchFiles = batches[index].files

                    for batchFileIndex in batchFiles.indices {
                        let batchFile = batchFiles[batchFileIndex]

                        if !files.contains(where: { $0.name == batchFile.fileName }) {
                            files.append(
                                RealDebrid.IAFile(
                                    name: batchFile.fileName,
                                    batchIndex: index,
                                    batchFileIndex: batchFileIndex
                                )
                            )
                        }
                    }
                }

                // TTL: 5 minutes
                availableHashes.append(
                    RealDebrid.IA(
                        magnet: Magnet(hash: hash, link: nil),
                        expiryTimeStamp: Date().timeIntervalSince1970 + 300,
                        files: files,
                        batches: batches
                    )
                )
            } else {
                availableHashes.append(
                    RealDebrid.IA(
                        magnet: Magnet(hash: hash, link: nil),
                        expiryTimeStamp: Date().timeIntervalSince1970 + 300
                    )
                )
            }
        }

        return availableHashes
    }

    // Adds a magnet link to the user's RD account
    public func addMagnet(magnet: Magnet) async throws -> String {
        guard let magnetLink = magnet.link else {
            throw RDError.FailedRequest(description: "The magnet link is invalid")
        }

        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/addMagnet")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "magnet", value: magnetLink)]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(AddMagnetResponse.self, from: data)

        return rawResponse.id
    }

    // Queues the magnet link for downloading
    public func selectFiles(debridID: String, fileIds: [Int]) async throws {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/selectFiles/\(debridID)")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()

        if fileIds.isEmpty {
            bodyComponents.queryItems = [URLQueryItem(name: "files", value: "all")]
        } else {
            let joinedIds = fileIds.map(String.init).joined(separator: ",")
            bodyComponents.queryItems = [URLQueryItem(name: "files", value: joinedIds)]
        }

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        try await performRequest(request: &request, requestName: #function)
    }

    // Gets the info of a torrent from a given ID
    public func torrentInfo(debridID: String, selectedIndex: Int?) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/info/\(debridID)")!)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(TorrentInfoResponse.self, from: data)

        // Let the user know if a torrent is downloading
        if let torrentLink = rawResponse.links[safe: selectedIndex ?? -1], rawResponse.status == "downloaded" {
            return torrentLink
        } else if rawResponse.status == "downloading" || rawResponse.status == "queued" {
            throw RDError.EmptyTorrents
        } else {
            throw RDError.EmptyData
        }
    }

    // Gets the user's torrent library
    public func userTorrents() async throws -> [UserTorrentsResponse] {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents")!)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode([UserTorrentsResponse].self, from: data)

        return rawResponse
    }

    // Deletes a torrent download from RD
    public func deleteTorrent(debridID: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/delete/\(debridID)")!)
        request.httpMethod = "DELETE"

        try await performRequest(request: &request, requestName: #function)
    }

    // Downloads link from selectFiles for playback
    public func unrestrictLink(debridDownloadLink: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/unrestrict/link")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "link", value: debridDownloadLink)]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(UnrestrictLinkResponse.self, from: data)

        return rawResponse.download
    }

    // Gets the user's downloads
    public func userDownloads() async throws -> [UserDownloadsResponse] {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/downloads")!)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode([UserDownloadsResponse].self, from: data)

        return rawResponse
    }

    public func deleteDownload(debridID: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/downloads/delete/\(debridID)")!)
        request.httpMethod = "DELETE"

        try await performRequest(request: &request, requestName: #function)
    }
}

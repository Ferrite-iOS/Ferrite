//
//  RealDebridWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/7/22.
//

import Foundation

public enum RealDebridError: Error {
    case InvalidUrl
    case InvalidPostBody
    case InvalidResponse
    case InvalidToken
    case EmptyData
    case FailedRequest(description: String)
    case AuthQuery(description: String)
}

public class RealDebrid: ObservableObject {
    var parentManager: DebridManager? = nil

    let jsonDecoder = JSONDecoder()
    let keychain = Keychain()

    let baseAuthUrl = "https://api.real-debrid.com/oauth/v2"
    let baseApiUrl = "https://api.real-debrid.com/rest/1.0"
    let openSourceClientId = "X245A4XAIBGVM"

    var authTask: Task<Void, Error>?

    // Fetches the device code from RD
    public func getVerificationInfo() async throws -> String {
        var urlComponents = URLComponents(string: "\(baseAuthUrl)/device/code")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: openSourceClientId),
            URLQueryItem(name: "new_credentials", value: "yes")
        ]

        guard let url = urlComponents.url else {
            throw RealDebridError.InvalidUrl
        }

        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let rawResponse = try jsonDecoder.decode(DeviceCodeResponse.self, from: data)

            // Spawn a separate process to get the device code
            Task {
                do {
                    try await getDeviceCredentials(deviceCode: rawResponse.deviceCode)
                } catch {
                    print("Authentication error in \(#function): \(error)")
                    authTask?.cancel()

                    Task { @MainActor in
                        parentManager?.toastModel?.toastDescription = "Authentication error in \(#function): \(error)"
                    }
                }
            }
            
            return rawResponse.directVerificationURL
        } catch {
            print("Couldn't get the new client creds!")
            throw RealDebridError.AuthQuery(description: error.localizedDescription)
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
            throw RealDebridError.InvalidUrl
        }

        let request = URLRequest(url: url)
        try await getDeviceCredentialsInternal(urlRequest: request, deviceCode: deviceCode)
    }

    // Timer to poll RD api for credentials
    func getDeviceCredentialsInternal(urlRequest: URLRequest, deviceCode: String) async throws {
        authTask = Task {
            var count = 0

            while count < 20 {
                let (data, _) = try await URLSession.shared.data(for: urlRequest)

                // We don't care if this fails
                let rawResponse = try? self.jsonDecoder.decode(DeviceCredentialsResponse.self, from: data)

                if let clientId = rawResponse?.clientID, let clientSecret = rawResponse?.clientSecret {
                    UserDefaults.standard.set(clientId, forKey: "RealDebrid.ClientId")
                    Keychain.shared.set(clientSecret, forKey: "RealDebrid.ClientSecret")

                    try await getTokens(deviceCode: deviceCode)

                    break
                } else {
                    try await Task.sleep(seconds: 5)
                    count += 1
                }
            }
        }
        
        if case let .failure(error) = await authTask?.result {
            throw error
        }
    }

    // Fetch all tokens for the user and store in keychain
    public func getTokens(deviceCode: String) async throws {
        guard let clientId = UserDefaults.standard.string(forKey: "RealDebrid.ClientId") else {
            throw RealDebridError.EmptyData
        }

        guard let clientSecret = Keychain.shared.get("RealDebrid.ClientSecret") else {
            throw RealDebridError.EmptyData
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

        Keychain.shared.set(rawResponse.accessToken, forKey: "RealDebrid.AccessToken")
        Keychain.shared.set(rawResponse.refreshToken, forKey: "RealDebrid.RefreshToken")

        let accessTimestamp = Date().timeIntervalSince1970 + Double(rawResponse.expiresIn)
        UserDefaults.standard.set(accessTimestamp, forKey: "RealDebrid.AccessTokenStamp")

        // Set AppStorage variable
        Task { @MainActor in
            parentManager?.realDebridEnabled = true
        }
    }

    public func fetchToken() async -> String? {
        let accessTokenStamp = UserDefaults.standard.double(forKey: "RealDebrid.AccessTokenStamp")

        if Date().timeIntervalSince1970 > accessTokenStamp {
            do {
                if let refreshToken = Keychain.shared.get("RealDebrid.RefreshToken") {
                    print("Refresh token found")
                    try await getTokens(deviceCode: refreshToken)
                }
            } catch {
                print(error)
                return nil
            }
        }

        return Keychain.shared.get("RealDebrid.AccessToken")
    }

    public func deleteTokens() async throws {
        Keychain.shared.delete("RealDebrid.RefreshToken")
        Keychain.shared.delete("RealDebrid.ClientSecret")
        UserDefaults.standard.removeObject(forKey: "RealDebrid.ClientId")
        UserDefaults.standard.removeObject(forKey: "RealDebrid.AccessTokenStamp")

        // Run the request, doesn't matter if it fails
        if let token = Keychain.shared.get("RealDebrid.AccessToken") {
            var request = URLRequest(url: URL(string: "\(baseApiUrl)/disable_access_token")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let _ = try? await URLSession.shared.data(for: request)

            Keychain.shared.delete("RealDebrid.AccessToken")
        }

        Task { @MainActor in
            parentManager?.realDebridEnabled = false
        }
    }

    // Wrapper request function which matches the responses and returns data
    @discardableResult public func performRequest(request: inout URLRequest, requestName: String) async throws -> Data {
        guard let token = await fetchToken() else {
            throw RealDebridError.InvalidToken
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw RealDebridError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode >= 200, response.statusCode <= 299 {
            return data
        } else if response.statusCode == 401 {
            try await deleteTokens()
            throw RealDebridError.FailedRequest(description: "The request \(requestName) failed because you were unauthorized. Please relogin to RealDebrid in Settings.")
        } else {
            throw RealDebridError.FailedRequest(description: "The request \(requestName) failed with status code \(response.statusCode).")
        }
    }

    // Checks if the magnet is streamable on RD
    // Currently does not work for batch links
    public func instantAvailability(magnetHashes: [String]) async throws -> [String] {
        var availableHashes: [String] = []
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/instantAvailability/\(magnetHashes.joined(separator: "/"))")!)

        let data = try await performRequest(request: &request, requestName: #function)

        // Does not account for torrent packs at the moment
        let rawResponseDict = try jsonDecoder.decode([String: InstantAvailabilityResponse].self, from: data)

        for (hash, response) in rawResponseDict {
            guard let data = response.data else {
                continue
            }

            // Do not include if a hash is a batch
            if !(data.rd.count > 1), !(data.rd[safe: 0]?.keys.count ?? 0 > 1) {
                availableHashes.append(hash)
            }
        }

        return availableHashes
    }

    // Adds a magnet link to the user's RD account
    public func addMagnet(magnetLink: String) async throws -> String {
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
    public func selectFiles(debridID: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/selectFiles/\(debridID)")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "files", value: "all")]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        try await performRequest(request: &request, requestName: #function)
    }

    // Fetches the info of a torrent
    public func torrentInfo(debridID: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/torrents/info/\(debridID)")!)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(TorrentInfoResponse.self, from: data)

        if let torrentLink = rawResponse.links[safe: 0] {
            return torrentLink
        } else {
            throw RealDebridError.EmptyData
        }
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
}

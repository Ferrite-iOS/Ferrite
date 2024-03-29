//
//  PremiumizeWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/28/22.
//

import Foundation

public class Premiumize {
    let jsonDecoder = JSONDecoder()

    let baseAuthUrl = "https://www.premiumize.me/authorize"
    let baseApiUrl = "https://www.premiumize.me/api"
    let clientId = "791565696"

    public func buildAuthUrl() throws -> URL {
        var urlComponents = URLComponents(string: baseAuthUrl)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]

        if let url = urlComponents.url {
            return url
        } else {
            throw PMError.InvalidUrl
        }
    }

    public func handleAuthCallback(url: URL) throws {
        let callbackComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        guard let callbackFragment = callbackComponents?.fragment else {
            throw PMError.InvalidResponse
        }

        var fragmentComponents = URLComponents()
        fragmentComponents.query = callbackFragment

        guard let accessToken = fragmentComponents.queryItems?.first(where: { $0.name == "access_token" })?.value else {
            throw PMError.InvalidToken
        }

        FerriteKeychain.shared.set(accessToken, forKey: "Premiumize.AccessToken")
    }

    // Adds a manual API key instead of web auth
    public func setApiKey(_ key: String) -> Bool {
        FerriteKeychain.shared.set(key, forKey: "Premiumize.AccessToken")
        UserDefaults.standard.set(true, forKey: "Premiumize.UseManualKey")

        return FerriteKeychain.shared.get("Premiumize.AccessToken") == key
    }

    public func getToken() -> String? {
        return FerriteKeychain.shared.get("Premiumize.AccessToken")
    }

    // Clears tokens. No endpoint to deregister a device
    public func deleteTokens() {
        FerriteKeychain.shared.delete("Premiumize.AccessToken")
        UserDefaults.standard.removeObject(forKey: "Premiumize.UseManualKey")
    }

    // Wrapper request function which matches the responses and returns data
    @discardableResult private func performRequest(request: inout URLRequest, requestName: String) async throws -> Data {
        guard let token = getToken() else {
            throw PMError.InvalidToken
        }

        // Use the API query parameter if a manual API key is present
        if UserDefaults.standard.bool(forKey: "Premiumize.UseManualKey") {
            guard
                let requestUrl = request.url,
                var components = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false)
            else {
                throw PMError.InvalidUrl
            }

            let apiTokenItem = URLQueryItem(name: "apikey", value: token)

            if components.queryItems == nil {
                components.queryItems = [apiTokenItem]
            } else {
                components.queryItems?.append(apiTokenItem)
            }

            request.url = components.url
        } else {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw PMError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode >= 200, response.statusCode <= 299 {
            return data
        } else if response.statusCode == 401 {
            deleteTokens()
            throw PMError.FailedRequest(description: "The request \(requestName) failed because you were unauthorized. Please relogin to Premiumize in Settings.")
        } else {
            throw PMError.FailedRequest(description: "The request \(requestName) failed with status code \(response.statusCode).")
        }
    }

    // Function to divide and execute cache endpoint requests in parallel
    // Calls this for 100 hashes at a time due to API limits
    public func divideCacheRequests(magnets: [Magnet]) async throws -> [Magnet] {
        let availableMagnets = try await withThrowingTaskGroup(of: [Magnet].self) { group in
            for chunk in magnets.chunked(into: 100) {
                group.addTask {
                    try await self.checkCache(magnets: chunk)
                }
            }

            var chunkedMagnets: [Magnet] = []
            for try await magnetArray in group {
                chunkedMagnets += magnetArray
            }

            return chunkedMagnets
        }

        return availableMagnets
    }

    // Parent function for initial checking of the cache
    func checkCache(magnets: [Magnet]) async throws -> [Magnet] {
        var urlComponents = URLComponents(string: "\(baseApiUrl)/cache/check")!
        urlComponents.queryItems = magnets.map { URLQueryItem(name: "items[]", value: $0.hash) }
        guard let url = urlComponents.url else {
            throw PMError.InvalidUrl
        }

        var request = URLRequest(url: url)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(CacheCheckResponse.self, from: data)

        if rawResponse.response.isEmpty {
            throw PMError.EmptyData
        } else {
            let availableMagnets = magnets.enumerated().compactMap { index, magnet in
                if rawResponse.response[safe: index] == true {
                    return magnet
                } else {
                    return nil
                }
            }

            return availableMagnets
        }
    }

    // Function to divide and execute DDL endpoint requests in parallel
    // Calls this for 10 requests at a time to not overwhelm API servers
    public func divideDDLRequests(magnetChunk: [Magnet]) async throws -> [IA] {
        let tempIA = try await withThrowingTaskGroup(of: Premiumize.IA.self) { group in
            for magnet in magnetChunk {
                group.addTask {
                    try await self.fetchDDL(magnet: magnet)
                }
            }

            var chunkedIA: [Premiumize.IA] = []
            for try await ia in group {
                chunkedIA.append(ia)
            }
            return chunkedIA
        }

        return tempIA
    }

    // Grabs DDL links
    func fetchDDL(magnet: Magnet) async throws -> IA {
        if magnet.hash == nil {
            throw PMError.EmptyData
        }

        var request = URLRequest(url: URL(string: "\(baseApiUrl)/transfer/directdl")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "src", value: magnet.link)]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(DDLResponse.self, from: data)

        if !rawResponse.content.isEmpty {
            let files = rawResponse.content.map { file in
                IAFile(
                    name: file.path.split(separator: "/").last.flatMap { String($0) } ?? file.path,
                    streamUrlString: file.link
                )
            }

            return IA(
                magnet: magnet,
                expiryTimeStamp: Date().timeIntervalSince1970 + 300,
                files: files
            )
        } else {
            throw PMError.EmptyData
        }
    }

    func createTransfer(magnet: Magnet) async throws {
        guard let magnetLink = magnet.link else {
            throw PMError.FailedRequest(description: "The magnet link is invalid")
        }

        var request = URLRequest(url: URL(string: "\(baseApiUrl)/transfer/create")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "src", value: magnetLink)]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        try await performRequest(request: &request, requestName: #function)
    }

    func userItems() async throws -> [UserItem] {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/item/listall")!)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(AllItemsResponse.self, from: data)

        if rawResponse.files.isEmpty {
            throw PMError.EmptyData
        }

        return rawResponse.files
    }

    func itemDetails(itemID: String) async throws -> ItemDetailsResponse {
        var urlComponents = URLComponents(string: "\(baseApiUrl)/item/details")!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: itemID)]
        guard let url = urlComponents.url else {
            throw PMError.InvalidUrl
        }

        var request = URLRequest(url: url)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ItemDetailsResponse.self, from: data)

        return rawResponse
    }

    func deleteItem(itemID: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseApiUrl)/item/delete")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "id", value: itemID)]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        try await performRequest(request: &request, requestName: #function)
    }
}

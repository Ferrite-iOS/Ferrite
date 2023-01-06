//
//  AllDebridWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/25/22.
//

import Foundation
import KeychainSwift

// TODO: Fix errors
public class AllDebrid {
    let jsonDecoder = JSONDecoder()
    let keychain = KeychainSwift()

    let baseApiUrl = "https://api.alldebrid.com/v4"
    let appName = "Ferrite"

    var authTask: Task<Void, Error>?

    // Fetches information for PIN auth
    public func getPinInfo() async throws -> PinResponse {
        let url = try buildRequestURL(urlString: "\(baseApiUrl)/pin/get")
        let request = URLRequest(url: url)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let rawResponse = try jsonDecoder.decode(ADResponse<PinResponse>.self, from: data).data

            return rawResponse
        } catch {
            print("Couldn't get pin information!")
            throw ADError.AuthQuery(description: error.localizedDescription)
        }
    }

    // Fetches API keys
    public func getApiKey(checkID: String, pin: String) async throws {
        let queryItems = [
            URLQueryItem(name: "agent", value: appName),
            URLQueryItem(name: "check", value: checkID),
            URLQueryItem(name: "pin", value: pin)
        ]

        let request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/pin/check", queryItems: queryItems))

        // Timer to poll AD API for key
        authTask = Task {
            var count = 0

            while count < 12 {
                if Task.isCancelled {
                    throw ADError.AuthQuery(description: "Token request cancelled.")
                }

                let (data, _) = try await URLSession.shared.data(for: request)

                // We don't care if this fails
                let rawResponse = try? self.jsonDecoder.decode(ADResponse<ApiKeyResponse>.self, from: data).data

                // If there's an API key from the response, end the task successfully
                if let apiKeyResponse = rawResponse {
                    keychain.set(apiKeyResponse.apikey, forKey: "AllDebrid.ApiKey")

                    return
                } else {
                    try await Task.sleep(seconds: 5)
                    count += 1
                }
            }

            throw ADError.AuthQuery(description: "Could not fetch the client ID and secret in time. Try logging in again.")
        }

        if case let .failure(error) = await authTask?.result {
            throw error
        }
    }

    // Clears tokens. No endpoint to deregister a device
    public func deleteTokens() {
        keychain.delete("AllDebrid.ApiKey")
    }

    // Wrapper request function which matches the responses and returns data
    @discardableResult private func performRequest(request: inout URLRequest, requestName: String) async throws -> Data {
        guard let token = keychain.get("AllDebrid.ApiKey") else {
            throw ADError.InvalidToken
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ADError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode >= 200, response.statusCode <= 299 {
            return data
        } else if response.statusCode == 401 {
            deleteTokens()
            throw ADError.FailedRequest(description: "The request \(requestName) failed because you were unauthorized. Please relogin to AllDebrid in Settings.")
        } else {
            throw ADError.FailedRequest(description: "The request \(requestName) failed with status code \(response.statusCode).")
        }
    }

    // Builds a URL for further requests
    private func buildRequestURL(urlString: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: urlString) else {
            throw ADError.InvalidUrl
        }

        components.queryItems = [
            URLQueryItem(name: "agent", value: appName)
        ] + queryItems

        if let url = components.url {
            return url
        } else {
            throw ADError.InvalidUrl
        }
    }

    // Adds a magnet link to the user's AD account
    public func addMagnet(magnet: Magnet) async throws -> Int {
        guard let magnetLink = magnet.link else {
            throw ADError.FailedRequest(description: "The magnet link is invalid")
        }

        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/magnet/upload"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "magnets[]", value: magnetLink)
        ]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ADResponse<AddMagnetResponse>.self, from: data).data

        if let magnet = rawResponse.magnets[safe: 0] {
            return magnet.id
        } else {
            throw ADError.InvalidResponse
        }
    }

    public func fetchMagnetStatus(magnetId: Int, selectedIndex: Int?) async throws -> String {
        let queryItems = [
            URLQueryItem(name: "id", value: String(magnetId))
        ]
        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/magnet/status", queryItems: queryItems))

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ADResponse<MagnetStatusResponse>.self, from: data).data

        // Better to fetch no link at all than the wrong link
        if let linkWrapper = rawResponse.magnets[safe: 0]?.links[safe: selectedIndex ?? -1] {
            return linkWrapper.link
        } else {
            throw ADError.EmptyTorrents
        }
    }

    public func userMagnets() async throws -> [MagnetStatusData] {
        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/magnet/status"))

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ADResponse<MagnetStatusResponse>.self, from: data).data

        if rawResponse.magnets.isEmpty {
            throw ADError.EmptyData
        } else {
            return rawResponse.magnets
        }
    }

    public func deleteMagnet(magnetId: Int) async throws {
        let queryItems = [
            URLQueryItem(name: "id", value: String(magnetId))
        ]
        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/magnet/delete", queryItems: queryItems))

        try await performRequest(request: &request, requestName: #function)
    }

    public func unlockLink(lockedLink: String) async throws -> String {
        let queryItems = [
            URLQueryItem(name: "link", value: lockedLink)
        ]
        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/link/unlock", queryItems: queryItems))

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ADResponse<UnlockLinkResponse>.self, from: data).data

        return rawResponse.link
    }

    public func instantAvailability(magnets: [Magnet]) async throws -> [IA] {
        let queryItems = magnets.map { URLQueryItem(name: "magnets[]", value: $0.hash) }
        var request = URLRequest(url: try buildRequestURL(urlString: "\(baseApiUrl)/magnet/instant", queryItems: queryItems))

        let data = try await performRequest(request: &request, requestName: #function)
        let rawResponse = try jsonDecoder.decode(ADResponse<InstantAvailabilityResponse>.self, from: data).data

        let filteredMagnets = rawResponse.magnets.filter { $0.instant == true && $0.files != nil }
        let availableHashes = filteredMagnets.map { magnetResp in
            // Force unwrap is OK here since the filter caught any nil values
            let files = magnetResp.files!.enumerated().map { index, magnetFile in
                IAFile(id: index, fileName: magnetFile.name)
            }

            return IA(
                magnet: Magnet(hash: magnetResp.hash, link: magnetResp.magnet),
                expiryTimeStamp: Date().timeIntervalSince1970 + 300,
                files: files
            )
        }

        return availableHashes
    }
}

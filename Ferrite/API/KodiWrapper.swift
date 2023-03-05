//
//  KodiWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import Foundation

public class Kodi {
    let encoder = JSONEncoder()

    public func sendVideoUrl(urlString: String) async throws {
        guard let baseUrl = UserDefaults.standard.string(forKey: "ExternalServices.KodiUrl") else {
            throw KodiError.InvalidBaseUrl
        }

        if URL(string: urlString) == nil {
            throw KodiError.InvalidPlaybackUrl
        }
        let username = UserDefaults.standard.string(forKey: "ExternalServices.KodiUsername")
        let password = UserDefaults.standard.string(forKey: "ExternalServices.KodiPassword")

        let requestBody = RPCPayload(
            method: "Player.Open",
            params: Params(item: Item(file: urlString))
        )

        var request = URLRequest(url: URL(string: "\(baseUrl)/jsonrpc")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let username, let password {
            request.setValue("Basic \(Data("\(username):\(password)".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try encoder.encode(requestBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw KodiError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode == 401 {
            throw KodiError.FailedRequest(description: "Your Kodi account details are invalid. Please check your credentials in Settings > Kodi.")
        } else if response.statusCode <= 200, response.statusCode >= 299 {
            throw KodiError.FailedRequest(description: "The Kodi request failed with status code \(response.statusCode).")
        }
    }
}

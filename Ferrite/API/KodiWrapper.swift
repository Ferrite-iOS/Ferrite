//
//  KodiWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import Foundation

public class Kodi {
    let encoder = JSONEncoder()

    // Used to add server to CoreData. Not part of API
    public func addServer(
        urlString: String,
        friendlyName: String?,
        username: String?,
        password: String?,
        existingServer: KodiServer? = nil
    ) throws {
        let backgroundContext = PersistenceController.shared.backgroundContext

        if !urlString.starts(with: "http://") && !urlString.starts(with: "https://") {
            throw KodiError.ServerAddition(description: "Could not add Kodi server because the URL is invalid.")
        }

        var name: String = ""
        if let friendlyName {
            name = friendlyName
        } else {
            var components = URLComponents(string: urlString)
            components?.scheme = nil
            components?.path = ""

            guard let cleanedName = components?.url?.description.dropFirst(2) else {
                throw KodiError.ServerAddition(description: "An invalid friendly name for this Kodi server was generated.")
            }

            name = String(cleanedName)
        }

        if existingServer == nil {
            let existingServerRequest = KodiServer.fetchRequest()
            existingServerRequest.fetchLimit = 1

            // If a server with the same name or URL exists, error out
            let namePredicate = NSPredicate(format: "name == %@", name)
            let urlPredicate = NSPredicate(format: "urlString == %@", urlString)
            existingServerRequest.predicate = NSCompoundPredicate(type: .or, subpredicates: [namePredicate, urlPredicate])

            if (try? backgroundContext.fetch(existingServerRequest).first) != nil {
                throw KodiError.ServerAddition(description: "An existing kodi server with the same name or URL was found. Please try editing an existing server instead.")
            }
        }

        let newServerObject = existingServer ?? KodiServer(context: backgroundContext)

        newServerObject.urlString = urlString
        newServerObject.name = name

        if let username, let password {
            newServerObject.username = username
            newServerObject.password = password
        }

        try backgroundContext.save()
    }

    public func ping(server: KodiServer) async throws {
        var request = URLRequest(url: URL(string: "\(server.urlString)/jsonrpc")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = RPCPayload(
            method: "JSONRPC.Ping",
            params: nil
        )

        if let username = server.username, let password = server.password {
            request.setValue("Basic \(Data("\(username):\(password)".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try encoder.encode(requestBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw KodiError.FailedRequest(description: "No HTTP response given")
        }

        if response.statusCode == 401 {
            throw KodiError.FailedRequest(description: "Your Kodi account details for server \(server.name) are invalid. Please check your credentials in Settings > Kodi.")
        } else if response.statusCode <= 200, response.statusCode >= 299 {
            throw KodiError.FailedRequest(description: "The Kodi request failed with status code \(response.statusCode).")
        }
    }

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

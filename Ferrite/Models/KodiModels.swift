//
//  KodiModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import Foundation

extension Kodi {
    enum KodiError: Error {
        case ServerAddition(description: String)
        case InvalidBaseUrl
        case InvalidPlaybackUrl
        case InvalidPostBody
        case FailedRequest(description: String)
    }

    // MARK: - RPC payload

    struct RPCPayload: Encodable {
        let jsonrpc: String = "2.0"
        let id: String = "1"
        let method: String
        let params: Params?
    }

    // MARK: - RPC Params

    struct Params: Codable {
        let item: Item
    }

    // MARK: - RPC Item

    struct Item: Codable {
        let file: String
    }
}

//
//  PremiumizeModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/28/22.
//

import Foundation

public extension Premiumize {
    // MARK: - Errors

    // TODO: Hybridize debrid errors in one structure
    enum PMError: Error {
        case InvalidUrl
        case InvalidPostBody
        case InvalidResponse
        case InvalidToken
        case EmptyData
        case EmptyTorrents
        case FailedRequest(description: String)
        case AuthQuery(description: String)
    }

    // MARK: - CacheCheckResponse

    struct CacheCheckResponse: Codable {
        let status: String
        let response: [Bool]
    }

    // MARK: - DDLResponse

    struct DDLResponse: Codable {
        let status: String
        let content: [DDLData]
        let location: String
        let filename: String
        let filesize: Int
    }

    // MARK: Content

    struct DDLData: Codable {
        let path: String
        let size: Int
        let link: String

        enum CodingKeys: String, CodingKey {
            case path, size, link
        }
    }

    // MARK: - InstantAvailability client side structures

    struct IA: Codable, Hashable {
        let magnet: Magnet
        let expiryTimeStamp: Double
        let files: [IAFile]
    }

    struct IAFile: Codable, Hashable {
        let name: String
        let streamUrlString: String
    }

    // MARK: - AllItemsResponse (listall endpoint)

    struct AllItemsResponse: Codable {
        let status: String
        let files: [UserItem]
    }

    // MARK: User Items

    // Abridged for required parameters
    struct UserItem: Codable {
        let id: String
        let name: String
        let mimeType: String

        enum CodingKeys: String, CodingKey {
            case id, name
            case mimeType = "mime_type"
        }
    }

    // MARK: - ItemDetailsResponse

    // Abridged for required parameters
    struct ItemDetailsResponse: Codable {
        let id: String
        let name: String
        let link: String
        let mimeType: String

        enum CodingKeys: String, CodingKey {
            case id, name, link
            case mimeType = "mime_type"
        }
    }
}

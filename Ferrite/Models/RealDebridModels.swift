//
//  RealDebridModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/19/22.
//
//  Structures generated from Quicktype

import Foundation

public extension RealDebrid {
    // MARK: - Errors

    // TODO: Hybridize debrid errors in one structure
    enum RDError: Error {
        case InvalidUrl
        case InvalidPostBody
        case InvalidResponse
        case InvalidToken
        case EmptyData
        case EmptyTorrents
        case FailedRequest(description: String)
        case AuthQuery(description: String)
    }

    // MARK: - device code endpoint

    struct DeviceCodeResponse: Codable, Sendable {
        let deviceCode, userCode: String
        let interval, expiresIn: Int
        let verificationURL, directVerificationURL: String

        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case interval
            case expiresIn = "expires_in"
            case verificationURL = "verification_url"
            case directVerificationURL = "direct_verification_url"
        }
    }

    // MARK: - device credentials endpoint

    struct DeviceCredentialsResponse: Codable, Sendable {
        let clientID, clientSecret: String?

        enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case clientSecret = "client_secret"
        }
    }

    // MARK: - token endpoint

    struct TokenResponse: Codable, Sendable {
        let accessToken: String
        let expiresIn: Int
        let refreshToken, tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
        }
    }

    // MARK: - instantAvailability endpoint

    // Thanks Skitty!
    struct InstantAvailabilityResponse: Codable, Sendable {
        var data: InstantAvailabilityData?

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let data = try? container.decode(InstantAvailabilityData.self) {
                self.data = data
            }
        }
    }

    internal struct InstantAvailabilityData: Codable, Sendable {
        var rd: [[String: InstantAvailabilityInfo]]
    }

    internal struct InstantAvailabilityInfo: Codable, Sendable {
        var filename: String
        var filesize: Int
    }

    // MARK: - Instant Availability client side structures

    struct IA: Codable, Hashable, Sendable {
        let magnet: Magnet
        let expiryTimeStamp: Double
        var files: [IAFile] = []
        var batches: [IABatch] = []
    }

    struct IABatch: Codable, Hashable, Sendable {
        let files: [IABatchFile]
    }

    struct IABatchFile: Codable, Hashable, Sendable {
        let id: Int
        let fileName: String
    }

    struct IAFile: Codable, Hashable, Sendable {
        let name: String
        let batchIndex: Int
        let batchFileIndex: Int
    }

    // MARK: - addMagnet endpoint

    struct AddMagnetResponse: Codable, Sendable {
        let id: String
        let uri: String
    }

    // MARK: - torrentInfo endpoint

    internal struct TorrentInfoResponse: Codable, Sendable {
        let id, filename, originalFilename, hash: String
        let bytes, originalBytes: Int
        let host: String
        let split, progress: Int
        let status, added: String
        let files: [TorrentInfoFile]
        let links: [String]
        let ended: String?
        let speed: Int?
        let seeders: Int?

        enum CodingKeys: String, CodingKey {
            case id, filename
            case originalFilename = "original_filename"
            case hash, bytes
            case originalBytes = "original_bytes"
            case host, split, progress, status, added, files, links, ended, speed, seeders
        }
    }

    internal struct TorrentInfoFile: Codable, Sendable {
        let id: Int
        let path: String
        let bytes, selected: Int
    }

    struct UserTorrentsResponse: Codable, Hashable, Sendable {
        let id, filename, hash: String
        let bytes: Int
        let host: String
        let split, progress: Int
        let status, added: String
        let links: [String]
        let speed, seeders: Int?
        let ended: String?
    }

    // MARK: - unrestrictLink endpoint

    internal struct UnrestrictLinkResponse: Codable, Sendable {
        let id, filename: String
        let mimeType: String?
        let filesize: Int
        let link: String
        let host: String
        let hostIcon: String
        let chunks, crc: Int
        let download: String
        let streamable: Int

        enum CodingKeys: String, CodingKey {
            case id, filename, mimeType, filesize, link, host
            case hostIcon = "host_icon"
            case chunks, crc, download, streamable
        }
    }

    // MARK: - User downloads list

    struct UserDownloadsResponse: Codable, Hashable, Sendable {
        let id, filename: String
        let mimeType: String?
        let filesize: Int
        let link: String
        let host: String
        let hostIcon: String
        let chunks: Int
        let download: String
        let streamable: Int
        let generated: String

        enum CodingKeys: String, CodingKey {
            case id, filename, mimeType, filesize, link, host
            case hostIcon = "host_icon"
            case chunks, download, streamable, generated
        }
    }
}

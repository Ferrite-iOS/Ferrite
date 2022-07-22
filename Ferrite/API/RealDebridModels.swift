//
//  RealDebridModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/5/22.
//
//  Structures generated from Quicktype

import Foundation

// MARK: - device code endpoint
public struct DeviceCodeResponse: Codable {
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
public struct DeviceCredentialsResponse: Codable {
    let clientID, clientSecret: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
    }
}

// MARK: - token endpoint
public struct TokenResponse: Codable {
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
struct InstantAvailabilityResponse: Codable {
    var data: InstantAvailabilityData?

    init(from decoder: Decoder) throws {
        let container =  try decoder.singleValueContainer()

        if let data = try? container.decode(InstantAvailabilityData.self) {
            self.data = data
        }
    }
}

struct InstantAvailabilityData: Codable {
    var rd: [[String: InstantAvailabilityInfo]]
}

struct InstantAvailabilityInfo: Codable {
    var filename: String
    var filesize: Int
}

// MARK: - addMagnet endpoint
public struct AddMagnetResponse: Codable {
    let id: String
    let uri: String
}

// MARK: - torrentInfo endpoint
struct TorrentInfoResponse: Codable {
    let id, filename, originalFilename, hash: String
    let bytes, originalBytes: Int
    let host: String
    let split, progress: Int
    let status, added: String
    let files: [TorrentInfoFile]
    let links: [String]
    let ended: String

    enum CodingKeys: String, CodingKey {
        case id, filename
        case originalFilename = "original_filename"
        case hash, bytes
        case originalBytes = "original_bytes"
        case host, split, progress, status, added, files, links, ended
    }
}

struct TorrentInfoFile: Codable {
    let id: Int
    let path: String
    let bytes, selected: Int
}

// MARK: - unrestrictLink endpoint
struct UnrestrictLinkResponse: Codable {
    let id, filename, mimeType: String
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

//
//  ActionModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//

import Foundation

public struct ActionJson: Codable, Hashable, PluginJson {
    public let name: String
    public let version: Int16
    let minVersion: String?
    let requires: [ActionRequirement]
    let deeplink: [DeeplinkActionJson]?
    public let author: String?
    public let listId: UUID?
    public let tags: [PluginTagJson]?

    public init(
        name: String,
        version: Int16,
        minVersion: String?,
        requires: [ActionRequirement],
        deeplink: [DeeplinkActionJson]?,
        author: String?,
        listId: UUID?,
        tags: [PluginTagJson]?
    ) {
        self.name = name
        self.version = version
        self.minVersion = minVersion
        self.requires = requires
        self.deeplink = deeplink
        self.author = author
        self.listId = listId
        self.tags = tags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.version = try container.decode(Int16.self, forKey: .version)
        self.minVersion = try container.decodeIfPresent(String.self, forKey: .minVersion)
        self.requires = try container.decode([ActionRequirement].self, forKey: .requires)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.listId = try container.decodeIfPresent(UUID.self, forKey: .listId)
        self.tags = try container.decodeIfPresent([PluginTagJson].self, forKey: .tags)

        if let deeplinkString = try? container.decode(String.self, forKey: .deeplink) {
            self.deeplink = [DeeplinkActionJson(os: [], scheme: deeplinkString)]
        } else if let deeplinkAction = try? container.decode([DeeplinkActionJson].self, forKey: .deeplink) {
            self.deeplink = deeplinkAction
        } else {
            self.deeplink = nil
        }
    }
}

public struct DeeplinkActionJson: Codable, Hashable {
    let os: [String]
    let scheme: String

    init(os: [String], scheme: String) {
        self.os = os
        self.scheme = scheme
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let os = try? container.decode(String.self, forKey: .os) {
            self.os = [os]
        } else if let os = try? container.decode([String].self, forKey: .os) {
            self.os = os
        } else {
            self.os = []
        }

        self.scheme = try container.decode(String.self, forKey: .scheme)
    }
}

public extension ActionJson {
    // Fetches all tags without optional requirement
    // Avoids the need for extra tag additions in DB
    func getTags() -> [PluginTagJson] {
        requires.map { PluginTagJson(name: $0.rawValue, colorHex: nil) } + (tags.map { $0 } ?? [])
    }
}

public enum ActionRequirement: String, Codable {
    case magnet
    case debrid
}

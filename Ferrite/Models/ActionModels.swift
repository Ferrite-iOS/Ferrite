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
    let deeplink: String?
    public var author: String?
    public var listId: UUID?
    public var tags: [PluginTagJson]?
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

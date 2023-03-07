//
//  PluginModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//

import Foundation

public struct PluginListJson: Codable {
    let name: String
    let author: String
    var sources: [SourceJson]?
    var actions: [ActionJson]?
}

// Color: Hex value
public struct PluginTagJson: Codable, Hashable, Sendable {
    public let name: String
    public let colorHex: String?

    enum CodingKeys: String, CodingKey {
        case name
        case colorHex = "color"
    }
}

extension PluginManager {
    enum PluginManagerError: Error {
        case ListAddition(description: String)
    }

    struct AvailablePlugins {
        let availableSources: [SourceJson]
        let availableActions: [ActionJson]
    }
}

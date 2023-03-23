//
//  Plugin.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/25/23.
//

import CoreData
import Foundation

public protocol Plugin: ObservableObject, NSManagedObject {
    var id: UUID { get set }
    var listId: UUID? { get set }
    var name: String { get set }
    var version: Int16 { get set }
    var author: String { get set }
    var enabled: Bool { get set }
    var tags: NSOrderedSet? { get set }
    func getTags() -> [PluginTagJson]
}

extension Plugin {
    var tagArray: [PluginTag] {
        tags?.array as? [PluginTag] ?? []
    }
}

public protocol PluginJson: Hashable {
    var name: String { get }
    var version: Int16 { get }
    var author: String? { get }
    var listId: UUID? { get }
    var listName: String? { get }
    var tags: [PluginTagJson]? { get }
    func getTags() -> [PluginTagJson]
}

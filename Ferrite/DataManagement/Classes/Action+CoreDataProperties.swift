//
//  Action+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/6/23.
//
//

import CoreData
import Foundation

public extension Action {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Action> {
        NSFetchRequest<Action>(entityName: "Action")
    }

    @NSManaged var id: UUID
    @NSManaged var listId: UUID?
    @NSManaged var name: String
    @NSManaged var deeplink: String?
    @NSManaged var version: Int16
    @NSManaged var requires: [String]
    @NSManaged var author: String
    @NSManaged var enabled: Bool
    @NSManaged var tags: NSOrderedSet?

    func getTags() -> [PluginTagJson] {
        requires.map { PluginTagJson(name: $0, colorHex: nil) } + tagArray.map { $0.toJson() }
    }
}

// MARK: Generated accessors for tags

public extension Action {
    @objc(insertObject:inTagsAtIndex:)
    @NSManaged func insertIntoTags(_ value: PluginTag, at idx: Int)

    @objc(removeObjectFromTagsAtIndex:)
    @NSManaged func removeFromTags(at idx: Int)

    @objc(insertTags:atIndexes:)
    @NSManaged func insertIntoTags(_ values: [PluginTag], at indexes: NSIndexSet)

    @objc(removeTagsAtIndexes:)
    @NSManaged func removeFromTags(at indexes: NSIndexSet)

    @objc(replaceObjectInTagsAtIndex:withObject:)
    @NSManaged func replaceTags(at idx: Int, with value: PluginTag)

    @objc(replaceTagsAtIndexes:withTags:)
    @NSManaged func replaceTags(at indexes: NSIndexSet, with values: [PluginTag])

    @objc(addTagsObject:)
    @NSManaged func addToTags(_ value: PluginTag)

    @objc(removeTagsObject:)
    @NSManaged func removeFromTags(_ value: PluginTag)

    @objc(addTags:)
    @NSManaged func addToTags(_ values: NSOrderedSet)

    @objc(removeTags:)
    @NSManaged func removeFromTags(_ values: NSOrderedSet)
}

extension Action: Identifiable {}

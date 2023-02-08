//
//  Action+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/6/23.
//
//

import Foundation
import CoreData


extension Action {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Action> {
        return NSFetchRequest<Action>(entityName: "Action")
    }

    @NSManaged public var id: UUID
    @NSManaged public var listId: UUID?
    @NSManaged public var name: String
    @NSManaged public var deeplink: String?
    @NSManaged public var version: Int16
    @NSManaged public var requires: [String]
    @NSManaged public var author: String
    @NSManaged public var enabled: Bool
    @NSManaged public var tags: NSOrderedSet?

    public func getTags() -> [PluginTagJson] {
        return requires.map { PluginTagJson(name: $0, colorHex: nil) } + tagArray.map { $0.toJson() }
    }
}

// MARK: Generated accessors for tags
extension Action {

    @objc(insertObject:inTagsAtIndex:)
    @NSManaged public func insertIntoTags(_ value: PluginTag, at idx: Int)

    @objc(removeObjectFromTagsAtIndex:)
    @NSManaged public func removeFromTags(at idx: Int)

    @objc(insertTags:atIndexes:)
    @NSManaged public func insertIntoTags(_ values: [PluginTag], at indexes: NSIndexSet)

    @objc(removeTagsAtIndexes:)
    @NSManaged public func removeFromTags(at indexes: NSIndexSet)

    @objc(replaceObjectInTagsAtIndex:withObject:)
    @NSManaged public func replaceTags(at idx: Int, with value: PluginTag)

    @objc(replaceTagsAtIndexes:withTags:)
    @NSManaged public func replaceTags(at indexes: NSIndexSet, with values: [PluginTag])

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: PluginTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: PluginTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSOrderedSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSOrderedSet)

}

extension Action : Identifiable {

}

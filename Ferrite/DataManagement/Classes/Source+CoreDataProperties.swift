//
//  Source+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/6/23.
//
//

import CoreData
import Foundation

public extension Source {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Source> {
        NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged var id: UUID
    @NSManaged var about: String?
    @NSManaged var website: String?
    @NSManaged var dynamicWebsite: Bool
    @NSManaged var fallbackUrls: [String]?
    @NSManaged var enabled: Bool
    @NSManaged var name: String
    @NSManaged var author: String
    @NSManaged var listId: UUID?
    @NSManaged var preferredParser: Int16
    @NSManaged var version: Int16
    @NSManaged var htmlParser: SourceHtmlParser?
    @NSManaged var rssParser: SourceRssParser?
    @NSManaged var jsonParser: SourceJsonParser?
    @NSManaged var api: SourceApi?
    @NSManaged var trackers: [String]?
    @NSManaged var tags: NSOrderedSet?

    func getTags() -> [PluginTagJson] {
        tagArray.map { $0.toJson() }
    }
}

// MARK: Generated accessors for tags

public extension Source {
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

extension Source: Identifiable {}

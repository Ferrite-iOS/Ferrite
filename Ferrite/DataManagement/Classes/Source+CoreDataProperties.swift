//
//  Source+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/6/23.
//
//

import Foundation
import CoreData


extension Source {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Source> {
        return NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged public var id: UUID
    @NSManaged public var baseUrl: String?
    @NSManaged public var fallbackUrls: [String]?
    @NSManaged public var dynamicBaseUrl: Bool
    @NSManaged public var enabled: Bool
    @NSManaged public var name: String
    @NSManaged public var author: String
    @NSManaged public var listId: UUID?
    @NSManaged public var preferredParser: Int16
    @NSManaged public var version: Int16
    @NSManaged public var htmlParser: SourceHtmlParser?
    @NSManaged public var rssParser: SourceRssParser?
    @NSManaged public var jsonParser: SourceJsonParser?
    @NSManaged public var api: SourceApi?
    @NSManaged public var trackers: [String]?
    @NSManaged public var tags: NSOrderedSet?

    public func getTags() -> [PluginTagJson] {
        return tagArray.map { $0.toJson() }
    }
}

// MARK: Generated accessors for tags
extension Source {

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

extension Source : Identifiable {

}

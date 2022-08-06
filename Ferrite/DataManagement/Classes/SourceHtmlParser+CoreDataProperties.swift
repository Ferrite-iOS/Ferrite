//
//  SourceHtmlParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import Foundation
import CoreData


extension SourceHtmlParser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SourceHtmlParser> {
        return NSFetchRequest<SourceHtmlParser>(entityName: "SourceHtmlParser")
    }

    @NSManaged public var rows: String
    @NSManaged public var searchUrl: String
    @NSManaged public var magnetLink: SourceMagnetLink?
    @NSManaged public var parentSource: Source?
    @NSManaged public var seedLeech: SourceSeedLeech?
    @NSManaged public var size: SourceSize?
    @NSManaged public var title: SourceTitle?
    @NSManaged public var magnetHash: SourceMagnetHash?
    @NSManaged public var trackers: NSSet?

}

// MARK: Generated accessors for trackers
extension SourceHtmlParser {

    @objc(addTrackersObject:)
    @NSManaged public func addToTrackers(_ value: SourceTracker)

    @objc(removeTrackersObject:)
    @NSManaged public func removeFromTrackers(_ value: SourceTracker)

    @objc(addTrackers:)
    @NSManaged public func addToTrackers(_ values: NSSet)

    @objc(removeTrackers:)
    @NSManaged public func removeFromTrackers(_ values: NSSet)

}

extension SourceHtmlParser : Identifiable {

}
//
//  SourceHtmlParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import CoreData
import Foundation

public extension SourceHtmlParser {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceHtmlParser> {
        NSFetchRequest<SourceHtmlParser>(entityName: "SourceHtmlParser")
    }

    @NSManaged var rows: String
    @NSManaged var searchUrl: String
    @NSManaged var magnetLink: SourceMagnetLink?
    @NSManaged var parentSource: Source?
    @NSManaged var seedLeech: SourceSeedLeech?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
    @NSManaged var magnetHash: SourceMagnetHash?
    @NSManaged var trackers: NSSet?
}

// MARK: Generated accessors for trackers

public extension SourceHtmlParser {
    @objc(addTrackersObject:)
    @NSManaged func addToTrackers(_ value: SourceTracker)

    @objc(removeTrackersObject:)
    @NSManaged func removeFromTrackers(_ value: SourceTracker)

    @objc(addTrackers:)
    @NSManaged func addToTrackers(_ values: NSSet)

    @objc(removeTrackers:)
    @NSManaged func removeFromTrackers(_ values: NSSet)
}

extension SourceHtmlParser: Identifiable {}

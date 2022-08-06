//
//  SourceRssParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import CoreData
import Foundation

public extension SourceRssParser {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceRssParser> {
        NSFetchRequest<SourceRssParser>(entityName: "SourceRssParser")
    }

    @NSManaged var items: String
    @NSManaged var searchUrl: String
    @NSManaged var rssUrl: String?
    @NSManaged var parentSource: Source?
    @NSManaged var trackers: NSSet?
    @NSManaged var magnetLink: SourceMagnetLink?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
    @NSManaged var seedLeech: SourceSeedLeech?
    @NSManaged var magnetHash: SourceMagnetHash?

    internal var trackerArray: [SourceTracker] {
        let trackerSet = trackers as? Set<SourceTracker> ?? []

        return trackerSet.map { $0 }
    }
}

// MARK: Generated accessors for trackers

public extension SourceRssParser {
    @objc(addTrackersObject:)
    @NSManaged func addToTrackers(_ value: SourceTracker)

    @objc(removeTrackersObject:)
    @NSManaged func removeFromTrackers(_ value: SourceTracker)

    @objc(addTrackers:)
    @NSManaged func addToTrackers(_ values: NSSet)

    @objc(removeTrackers:)
    @NSManaged func removeFromTrackers(_ values: NSSet)
}

extension SourceRssParser: Identifiable {}

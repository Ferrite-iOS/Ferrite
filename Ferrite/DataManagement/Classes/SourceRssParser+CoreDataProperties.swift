//
//  SourceRssParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import Foundation
import CoreData


extension SourceRssParser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SourceRssParser> {
        return NSFetchRequest<SourceRssParser>(entityName: "SourceRssParser")
    }

    @NSManaged public var items: String
    @NSManaged public var searchUrl: String
    @NSManaged public var rssUrl: String?
    @NSManaged public var parentSource: Source?
    @NSManaged public var trackers: NSSet?
    @NSManaged public var magnetLink: SourceMagnetLink?
    @NSManaged public var size: SourceSize?
    @NSManaged public var title: SourceTitle?
    @NSManaged public var seedLeech: SourceSeedLeech?
    @NSManaged public var magnetHash: SourceMagnetHash?

    var trackerArray: [SourceTracker] {
        let trackerSet = trackers as? Set<SourceTracker> ?? []

        return trackerSet.map { $0 }
    }
}

// MARK: Generated accessors for trackers
extension SourceRssParser {

    @objc(addTrackersObject:)
    @NSManaged public func addToTrackers(_ value: SourceTracker)

    @objc(removeTrackersObject:)
    @NSManaged public func removeFromTrackers(_ value: SourceTracker)

    @objc(addTrackers:)
    @NSManaged public func addToTrackers(_ values: NSSet)

    @objc(removeTrackers:)
    @NSManaged public func removeFromTrackers(_ values: NSSet)

}

extension SourceRssParser : Identifiable {

}

//
//  SourceRssParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/20/22.
//
//

import Foundation
import CoreData


extension SourceRssParser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SourceRssParser> {
        return NSFetchRequest<SourceRssParser>(entityName: "SourceRssParser")
    }

    @NSManaged public var items: String
    @NSManaged public var rssUrl: String?
    @NSManaged public var searchUrl: String
    @NSManaged public var trackers: [String]?
    @NSManaged public var magnetHash: SourceMagnetHash?
    @NSManaged public var magnetLink: SourceMagnetLink?
    @NSManaged public var parentSource: Source?
    @NSManaged public var seedLeech: SourceSeedLeech?
    @NSManaged public var size: SourceSize?
    @NSManaged public var title: SourceTitle?

}

extension SourceRssParser : Identifiable {

}

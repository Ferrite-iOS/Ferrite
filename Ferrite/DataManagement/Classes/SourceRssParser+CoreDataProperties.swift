//
//  SourceRssParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/20/22.
//
//

import CoreData
import Foundation

public extension SourceRssParser {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceRssParser> {
        NSFetchRequest<SourceRssParser>(entityName: "SourceRssParser")
    }

    @NSManaged var items: String
    @NSManaged var rssUrl: String?
    @NSManaged var searchUrl: String
    @NSManaged var magnetHash: SourceMagnetHash?
    @NSManaged var magnetLink: SourceMagnetLink?
    @NSManaged var parentSource: Source?
    @NSManaged var seedLeech: SourceSeedLeech?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
}

extension SourceRssParser: Identifiable {}

//
//  SourceHtmlParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/2/22.
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
    @NSManaged var magnet: SourceMagnet?
    @NSManaged var parentSource: Source?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
    @NSManaged var seedLeech: SourceSeedLeech?
}

extension SourceHtmlParser: Identifiable {}

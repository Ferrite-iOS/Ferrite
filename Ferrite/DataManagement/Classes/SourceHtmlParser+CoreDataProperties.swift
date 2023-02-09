//
//  SourceHtmlParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/20/22.
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
    @NSManaged var magnetHash: SourceMagnetHash?
    @NSManaged var magnetLink: SourceMagnetLink?
    @NSManaged var parentSource: Source?
    @NSManaged var seedLeech: SourceSeedLeech?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
    @NSManaged var subName: SourceSubName?
}

extension SourceHtmlParser: Identifiable {}

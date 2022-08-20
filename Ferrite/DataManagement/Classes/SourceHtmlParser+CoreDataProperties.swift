//
//  SourceHtmlParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/20/22.
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
    @NSManaged public var trackers: [String]?
    @NSManaged public var magnetHash: SourceMagnetHash?
    @NSManaged public var magnetLink: SourceMagnetLink?
    @NSManaged public var parentSource: Source?
    @NSManaged public var seedLeech: SourceSeedLeech?
    @NSManaged public var size: SourceSize?
    @NSManaged public var title: SourceTitle?

}

extension SourceHtmlParser : Identifiable {

}

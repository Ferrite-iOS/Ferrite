//
//  SourceJsonParser+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/21/22.
//
//

import CoreData
import Foundation

public extension SourceJsonParser {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceJsonParser> {
        NSFetchRequest<SourceJsonParser>(entityName: "SourceJsonParser")
    }

    @NSManaged var results: String?
    @NSManaged var subResults: String?
    @NSManaged var searchUrl: String
    @NSManaged var magnetHash: SourceMagnetHash?
    @NSManaged var magnetLink: SourceMagnetLink?
    @NSManaged var parentSource: Source?
    @NSManaged var seedLeech: SourceSeedLeech?
    @NSManaged var size: SourceSize?
    @NSManaged var title: SourceTitle?
    @NSManaged var subName: SourceSubName?
}

extension SourceJsonParser: Identifiable {}

//
//  SourceSeedLeech+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/2/22.
//
//

import CoreData
import Foundation

public extension SourceSeedLeech {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceSeedLeech> {
        NSFetchRequest<SourceSeedLeech>(entityName: "SourceSeedLeech")
    }

    @NSManaged var combined: String?
    @NSManaged var leecherRegex: String?
    @NSManaged var leechers: String?
    @NSManaged var seederRegex: String?
    @NSManaged var seeders: String?
    @NSManaged var attribute: String
    @NSManaged var discriminator: String?
    @NSManaged var parentParser: SourceHtmlParser?
}

extension SourceSeedLeech: Identifiable {}

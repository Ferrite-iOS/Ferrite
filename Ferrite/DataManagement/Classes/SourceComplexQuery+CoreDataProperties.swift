//
//  SourceComplexQuery+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/22/22.
//
//

import CoreData
import Foundation

public extension SourceComplexQuery {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceComplexQuery> {
        NSFetchRequest<SourceComplexQuery>(entityName: "SourceComplexQuery")
    }

    @NSManaged var attribute: String
    @NSManaged var discriminator: String?
    @NSManaged var query: String
    @NSManaged var regex: String?
}

extension SourceComplexQuery: Identifiable {}

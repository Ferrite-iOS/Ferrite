//
//  Source+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/30/22.
//
//

import CoreData
import Foundation

public extension Source {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Source> {
        NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged var name: String
    @NSManaged var enabled: Bool
    @NSManaged var version: String
    @NSManaged var baseUrl: String
    @NSManaged var htmlParser: SourceHtmlParser?
}

extension Source: Identifiable {}

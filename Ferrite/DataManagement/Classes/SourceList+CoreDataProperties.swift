//
//  SourceList+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/30/22.
//
//

import CoreData
import Foundation

public extension SourceList {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceList> {
        NSFetchRequest<SourceList>(entityName: "SourceList")
    }

    @NSManaged var id: UUID
    @NSManaged var author: String
    @NSManaged var name: String
    @NSManaged var urlString: String
}

extension SourceList: Identifiable {}

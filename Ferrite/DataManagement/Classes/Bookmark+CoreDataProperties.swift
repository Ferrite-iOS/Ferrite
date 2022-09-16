//
//  Bookmark+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/3/22.
//
//

import CoreData
import Foundation

public extension Bookmark {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Bookmark> {
        NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged var leechers: String?
    @NSManaged var magnetHash: String?
    @NSManaged var magnetLink: String?
    @NSManaged var seeders: String?
    @NSManaged var size: String?
    @NSManaged var source: String
    @NSManaged var title: String?
    @NSManaged var orderNum: Int16
}

extension Bookmark: Identifiable {}

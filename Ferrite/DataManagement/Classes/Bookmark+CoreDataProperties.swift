//
//  Bookmark+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/3/22.
//
//

import Foundation
import CoreData


extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var leechers: String?
    @NSManaged public var magnetHash: String?
    @NSManaged public var magnetLink: String?
    @NSManaged public var seeders: String?
    @NSManaged public var size: String?
    @NSManaged public var source: String
    @NSManaged public var title: String?
    @NSManaged public var orderNum: Int16

}

extension Bookmark : Identifiable {

}

//
//  Source+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import Foundation
import CoreData


extension Source {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Source> {
        return NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged public var id: UUID
    @NSManaged public var baseUrl: String
    @NSManaged public var enabled: Bool
    @NSManaged public var name: String
    @NSManaged public var author: String
    @NSManaged public var listId: UUID?
    @NSManaged public var preferredParser: Int16
    @NSManaged public var version: Int16
    @NSManaged public var htmlParser: SourceHtmlParser?
    @NSManaged public var rssParser: SourceRssParser?

}

extension Source : Identifiable {

}

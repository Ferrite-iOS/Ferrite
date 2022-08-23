//
//  Source+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import CoreData
import Foundation

public extension Source {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Source> {
        NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged var id: UUID
    @NSManaged var baseUrl: String?
    @NSManaged var dynamicBaseUrl: Bool
    @NSManaged var enabled: Bool
    @NSManaged var name: String
    @NSManaged var author: String
    @NSManaged var listId: UUID?
    @NSManaged var preferredParser: Int16
    @NSManaged var version: Int16
    @NSManaged var htmlParser: SourceHtmlParser?
    @NSManaged var rssParser: SourceRssParser?
    @NSManaged var jsonParser: SourceJsonParser?
    @NSManaged var api: SourceApi?
    @NSManaged var trackers: [String]?
}

extension Source: Identifiable {}

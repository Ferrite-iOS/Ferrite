//
//  TorrentSource+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//
//

import Foundation
import CoreData


extension TorrentSource {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TorrentSource> {
        return NSFetchRequest<TorrentSource>(entityName: "TorrentSource")
    }

    @NSManaged public var enabled: Bool
    @NSManaged public var linkQuery: String
    @NSManaged public var name: String?
    @NSManaged public var rowQuery: String
    @NSManaged public var sizeQuery: String?
    @NSManaged public var titleQuery: String?
    @NSManaged public var url: String

}

extension TorrentSource : Identifiable {

}

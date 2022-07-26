//
//  TorrentSource+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//
//

import CoreData
import Foundation

public extension TorrentSource {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TorrentSource> {
        NSFetchRequest<TorrentSource>(entityName: "TorrentSource")
    }

    @NSManaged var enabled: Bool
    @NSManaged var linkQuery: String
    @NSManaged var name: String?
    @NSManaged var rowQuery: String
    @NSManaged var sizeQuery: String?
    @NSManaged var titleQuery: String?
    @NSManaged var url: String
}

extension TorrentSource: Identifiable {}

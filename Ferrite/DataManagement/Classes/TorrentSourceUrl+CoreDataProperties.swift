//
//  TorrentSourceUrl+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//
//

import CoreData
import Foundation

public extension TorrentSourceUrl {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TorrentSourceUrl> {
        NSFetchRequest<TorrentSourceUrl>(entityName: "TorrentSourceUrl")
    }

    @NSManaged var urlString: String
    @NSManaged var repoName: String?
    @NSManaged var repoAuthor: String?
}

extension TorrentSourceUrl: Identifiable {}

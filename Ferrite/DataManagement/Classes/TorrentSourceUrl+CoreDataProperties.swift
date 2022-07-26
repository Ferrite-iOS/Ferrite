//
//  TorrentSourceUrl+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//
//

import Foundation
import CoreData


extension TorrentSourceUrl {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TorrentSourceUrl> {
        return NSFetchRequest<TorrentSourceUrl>(entityName: "TorrentSourceUrl")
    }

    @NSManaged public var urlString: String
    @NSManaged public var repoName: String?
    @NSManaged public var repoAuthor: String?

}

extension TorrentSourceUrl : Identifiable {

}

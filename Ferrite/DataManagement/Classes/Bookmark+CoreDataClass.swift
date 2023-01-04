//
//  Bookmark+CoreDataClass.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//
//

import CoreData
import Foundation

@objc(Bookmark)
public class Bookmark: NSManagedObject {
    func toSearchResult() -> SearchResult {
        SearchResult(
            title: title,
            source: source,
            size: size,
            magnet: Magnet(hash: magnetHash, link: magnetLink),
            seeders: seeders,
            leechers: leechers
        )
    }
}

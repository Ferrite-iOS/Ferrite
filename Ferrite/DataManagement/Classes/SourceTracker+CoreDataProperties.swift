//
//  SourceTracker+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import CoreData
import Foundation

public extension SourceTracker {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceTracker> {
        NSFetchRequest<SourceTracker>(entityName: "SourceTracker")
    }

    @NSManaged var urlString: String
    @NSManaged var parentRssParser: SourceRssParser?
    @NSManaged var parentHtmlParser: SourceHtmlParser?
}

extension SourceTracker: Identifiable {}

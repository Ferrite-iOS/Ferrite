//
//  SourceTracker+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/3/22.
//
//

import Foundation
import CoreData


extension SourceTracker {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SourceTracker> {
        return NSFetchRequest<SourceTracker>(entityName: "SourceTracker")
    }

    @NSManaged public var urlString: String
    @NSManaged public var parentRssParser: SourceRssParser?
    @NSManaged public var parentHtmlParser: SourceHtmlParser?

}

extension SourceTracker : Identifiable {

}

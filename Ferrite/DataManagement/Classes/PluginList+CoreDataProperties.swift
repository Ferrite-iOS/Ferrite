//
//  PluginList+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//
//

import Foundation
import CoreData


extension PluginList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PluginList> {
        return NSFetchRequest<PluginList>(entityName: "PluginList")
    }

    @NSManaged public var author: String
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var urlString: String

}

extension PluginList : Identifiable {

}

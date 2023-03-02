//
//  PluginList+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//
//

import CoreData
import Foundation

public extension PluginList {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PluginList> {
        NSFetchRequest<PluginList>(entityName: "PluginList")
    }

    @NSManaged var author: String
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var urlString: String
}

extension PluginList: Identifiable {}

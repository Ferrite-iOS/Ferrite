//
//  PluginTag+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/7/23.
//
//

import CoreData
import Foundation

public extension PluginTag {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PluginTag> {
        NSFetchRequest<PluginTag>(entityName: "PluginTag")
    }

    @NSManaged var colorHex: String?
    @NSManaged var name: String
    @NSManaged var parentAction: Action?
    @NSManaged var parentSource: Source?

    internal func toJson() -> PluginTagJson {
        PluginTagJson(name: name, colorHex: colorHex)
    }
}

extension PluginTag: Identifiable {}

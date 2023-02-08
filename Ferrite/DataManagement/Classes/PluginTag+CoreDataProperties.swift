//
//  PluginTag+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/7/23.
//
//

import Foundation
import CoreData


extension PluginTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PluginTag> {
        return NSFetchRequest<PluginTag>(entityName: "PluginTag")
    }

    @NSManaged public var colorHex: String?
    @NSManaged public var name: String
    @NSManaged public var parentAction: Action?
    @NSManaged public var parentSource: Source?

    func toJson() -> PluginTagJson {
        return PluginTagJson(name: name, colorHex: colorHex)
    }
}

extension PluginTag : Identifiable {

}

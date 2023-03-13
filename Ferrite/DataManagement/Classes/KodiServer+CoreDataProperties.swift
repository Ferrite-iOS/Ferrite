//
//  KodiServer+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/6/23.
//
//

import Foundation
import CoreData


extension KodiServer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KodiServer> {
        return NSFetchRequest<KodiServer>(entityName: "KodiServer")
    }

    @NSManaged public var urlString: String
    @NSManaged public var name: String
    @NSManaged public var username: String?
    @NSManaged public var password: String?

}

extension KodiServer : Identifiable {

}

//
//  KodiServer+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/6/23.
//
//

import CoreData
import Foundation

public extension KodiServer {
    @nonobjc class func fetchRequest() -> NSFetchRequest<KodiServer> {
        NSFetchRequest<KodiServer>(entityName: "KodiServer")
    }

    @NSManaged var urlString: String
    @NSManaged var name: String
    @NSManaged var username: String?
    @NSManaged var password: String?
}

extension KodiServer: Identifiable {}

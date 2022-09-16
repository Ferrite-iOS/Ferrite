//
//  History+CoreDataProperties.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/4/22.
//
//

import CoreData
import Foundation

public extension History {
    @nonobjc class func fetchRequest() -> NSFetchRequest<History> {
        NSFetchRequest<History>(entityName: "History")
    }

    @NSManaged var date: Date?
    @NSManaged var dateString: String?
    @NSManaged var entries: NSSet?

    internal var entryArray: [HistoryEntry] {
        let entrySet = entries as? Set<HistoryEntry> ?? []

        return entrySet.sorted {
            $0.timeStamp > $1.timeStamp
        }
    }
}

// MARK: Generated accessors for entries

public extension History {
    @objc(addEntriesObject:)
    @NSManaged func addToEntries(_ value: HistoryEntry)

    @objc(removeEntriesObject:)
    @NSManaged func removeFromEntries(_ value: HistoryEntry)

    @objc(addEntries:)
    @NSManaged func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged func removeFromEntries(_ values: NSSet)
}

extension History: Identifiable {}

//
//  PersistenceController.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import CoreData

enum HistoryDeleteRange {
    case day
    case week
    case month
    case allTime
}

enum HistoryDeleteError: Error {
    case noDate(String)
    case unknown(String)
}

// No iCloud until finalized sources
struct PersistenceController {
    static var shared = PersistenceController()

    // Coredata storage
    let container: NSPersistentContainer

    // Background context for writes
    let backgroundContext: NSManagedObjectContext

    // Coredata load
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FerriteDB")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("CoreData: Failed to find a persistent store description")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData init error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        try? container.viewContext.setQueryGenerationFrom(.current)

        backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        try? backgroundContext.setQueryGenerationFrom(.current)
    }

    func save(_ context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                debugPrint("Error in CoreData saving! \(error.localizedDescription)")
            }
        }
    }

    // By default, delete objects using the ViewContext unless specified
    func delete(_ object: NSManagedObject, context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext

        if context != container.viewContext {
            let wrappedObject = try? context.existingObject(with: object.objectID)

            if let backgroundObject = wrappedObject {
                context.delete(backgroundObject)
                save(context)

                return
            }
        }

        container.viewContext.delete(object)
        save()
    }

    
    func getHistoryPredicate(range: HistoryDeleteRange) -> NSPredicate? {
        if range == .allTime {
            return nil
        }

        var components = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let today = Calendar.current.date(from: components) else {
            return nil
        }

        var offsetComponents = DateComponents(day: 1)
        guard let tomorrow = Calendar.current.date(byAdding: offsetComponents, to: today) else {
            return nil
        }

        switch range {
        case .week:
            offsetComponents.day = -7
        case .month:
            offsetComponents.day = -28
        default:
            break
        }

        guard var offsetDate = Calendar.current.date(byAdding: offsetComponents, to: today) else {
            return nil
        }

        if TimeZone.current.isDaylightSavingTime(for: offsetDate) {
            offsetDate = offsetDate.addingTimeInterval(3600)
        }

        let predicate = NSPredicate(format: "date >= %@ && date < %@", range == .day ? today as NSDate : offsetDate as NSDate, tomorrow as NSDate)

        return predicate
    }

    // Always use the background context to batch delete
    // Merge changes into both contexts to update views
    func batchDeleteHistory(range: HistoryDeleteRange) throws {
        let predicate = getHistoryPredicate(range: range)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "History")

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        } else if range != .allTime {
            throw HistoryDeleteError.noDate("No history date range was provided and you weren't trying to clear everything! Try relaunching the app?")
        }

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext, backgroundContext])
    }
}

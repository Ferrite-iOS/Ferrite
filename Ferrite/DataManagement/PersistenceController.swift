//
//  PersistenceController.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import CoreData

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
}

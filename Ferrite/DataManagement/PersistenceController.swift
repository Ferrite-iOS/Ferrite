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
    static let shared = PersistenceController()

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
            if let error {
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

    func createBookmark(_ bookmarkJson: BookmarkJson, performSave: Bool) {
        let bookmarkRequest = Bookmark.fetchRequest()
        bookmarkRequest.predicate = NSPredicate(
            format: "source == %@ AND title == %@ AND magnetLink == %@",
            bookmarkJson.source,
            bookmarkJson.title ?? "",
            bookmarkJson.magnetLink ?? ""
        )

        if (try? backgroundContext.fetch(bookmarkRequest).first) != nil {
            return
        }

        let newBookmark = Bookmark(context: backgroundContext)

        newBookmark.title = bookmarkJson.title
        newBookmark.source = bookmarkJson.source
        newBookmark.magnetHash = bookmarkJson.magnetHash
        newBookmark.magnetLink = bookmarkJson.magnetLink
        newBookmark.seeders = bookmarkJson.seeders
        newBookmark.leechers = bookmarkJson.leechers

        if performSave {
            save(backgroundContext)
        }
    }

    func createHistory(_ entryJson: HistoryEntryJson, performSave: Bool, isBackup: Bool = false, date: Double? = nil) {
        let historyDate = date.map { Date(timeIntervalSince1970: $0) } ?? Date()
        let historyDateString = DateFormatter.historyDateFormatter.string(from: historyDate)

        let historyRequest = History.fetchRequest()
        historyRequest.predicate = NSPredicate(format: "dateString = %@", historyDateString)
        var existingHistory: History?

        if var histories = try? backgroundContext.fetch(historyRequest) {
            for (i, history) in histories.enumerated() {
                let existingEntries = history.entryArray.filter { $0.url == entryJson.url && $0.name == entryJson.name }

                // Maybe add !isBackup here
                if !existingEntries.isEmpty {
                    if isBackup {
                        continue
                    } else {
                        for entry in existingEntries {
                            PersistenceController.shared.delete(entry, context: backgroundContext)
                        }
                    }
                }

                if history.entryArray.isEmpty {
                    PersistenceController.shared.delete(history, context: backgroundContext)
                    histories.remove(at: i)
                }
            }

            existingHistory = histories.first
        }

        let newHistoryEntry = HistoryEntry(context: backgroundContext)

        newHistoryEntry.source = entryJson.source
        newHistoryEntry.name = entryJson.name
        newHistoryEntry.url = entryJson.url
        newHistoryEntry.subName = entryJson.subName
        newHistoryEntry.timeStamp = entryJson.timeStamp ?? Date().timeIntervalSince1970

        newHistoryEntry.parentHistory = existingHistory ?? History(context: backgroundContext)
        newHistoryEntry.parentHistory?.dateString = historyDateString
        newHistoryEntry.parentHistory?.date = historyDate

        if performSave {
            save(backgroundContext)
        }
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

    // Wrapper to batch delete history objects
    func batchDeleteHistory(range: HistoryDeleteRange) throws {
        let predicate = getHistoryPredicate(range: range)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "History")

        if let predicate {
            fetchRequest.predicate = predicate
        } else if range != .allTime {
            throw HistoryDeleteError.noDate("No history date range was provided and you weren't trying to clear everything! Try relaunching the app?")
        }

        try batchDelete("History", predicate: predicate)
    }

    // Always use the background context to batch delete
    // Merge changes into both contexts to update views
    func batchDelete(_ entity: String, predicate: NSPredicate? = nil) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext, backgroundContext])
    }
}

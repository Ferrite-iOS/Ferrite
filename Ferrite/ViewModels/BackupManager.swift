//
//  BackupManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/16/22.
//

import Foundation

public class BackupManager: ObservableObject {
    var toastModel: ToastViewModel?

    @Published var showRestoreAlert = false
    @Published var showRestoreCompletedAlert = false

    @Published var backupUrls: [URL] = []
    @Published var backupSourceNames: [String] = []
    @Published var selectedBackupUrl: URL?

    func createBackup() {
        var backup = Backup()
        let backgroundContext = PersistenceController.shared.backgroundContext

        let bookmarkRequest = Bookmark.fetchRequest()
        if let fetchedBookmarks = try? backgroundContext.fetch(bookmarkRequest) {
            backup.bookmarks = fetchedBookmarks.compactMap {
                BookmarkJson(
                    title: $0.title,
                    source: $0.source,
                    size: $0.size,
                    magnetLink: $0.magnetLink,
                    magnetHash: $0.magnetHash,
                    seeders: $0.seeders,
                    leechers: $0.leechers
                )
            }
        }

        let historyRequest = History.fetchRequest()
        if let fetchedHistory = try? backgroundContext.fetch(historyRequest) {
            backup.history = fetchedHistory.compactMap { history in
                if history.entries == nil {
                    return nil
                } else {
                    return HistoryJson(
                        dateString: history.dateString,
                        date: history.date?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                        entries: history.entryArray.compactMap { entry in
                            if let name = entry.name, let url = entry.url {
                                return HistoryEntryJson(
                                    name: name,
                                    subName: entry.subName,
                                    url: url,
                                    timeStamp: entry.timeStamp,
                                    source: entry.source
                                )
                            } else {
                                return nil
                            }
                        }
                    )
                }
            }
        }

        let sourceRequest = Source.fetchRequest()
        if let sources = try? backgroundContext.fetch(sourceRequest) {
            backup.sourceNames = sources.map(\.name)
        }

        let sourceListRequest = SourceList.fetchRequest()
        if let sourceLists = try? backgroundContext.fetch(sourceListRequest) {
            backup.sourceLists = sourceLists.map {
                SourceListBackupJson(
                    name: $0.name,
                    author: $0.author,
                    id: $0.id.uuidString,
                    urlString: $0.urlString
                )
            }
        }

        do {
            let encodedJson = try JSONEncoder().encode(backup)
            let backupsPath = FileManager.default.appDirectory.appendingPathComponent("Backups")
            if !FileManager.default.fileExists(atPath: backupsPath.path) {
                try FileManager.default.createDirectory(atPath: backupsPath.path, withIntermediateDirectories: true, attributes: nil)
            }

            let snapshot = Int(Date().timeIntervalSince1970.rounded())
            let writeUrl = backupsPath.appendingPathComponent("Ferrite-backup-\(snapshot).feb")

            try encodedJson.write(to: writeUrl)
            backupUrls.append(writeUrl)
        } catch {
            print(error)
        }
    }

    // Backup is in local documents directory, so no need to restore it from the shared URL
    func restoreBackup() {
        guard let backupUrl = selectedBackupUrl else {
            Task {
                await toastModel?.updateToastDescription("Could not find the selected backup in the local directory.")
            }

            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext

        do {
            let file = try Data(contentsOf: backupUrl)

            let backup = try JSONDecoder().decode(Backup.self, from: file)

            if let bookmarks = backup.bookmarks {
                for bookmark in bookmarks {
                    PersistenceController.shared.createBookmark(bookmark)
                }
            }

            if let storedHistories = backup.history {
                for storedHistory in storedHistories {
                    for storedEntry in storedHistory.entries {
                        PersistenceController.shared.createHistory(entryJson: storedEntry, date: storedHistory.date)
                    }
                }
            }

            if let storedLists = backup.sourceLists {
                for list in storedLists {
                    let sourceListRequest = SourceList.fetchRequest()
                    let urlPredicate = NSPredicate(format: "urlString == %@", list.urlString)
                    let infoPredicate = NSPredicate(format: "author == %@ AND name == %@", list.author, list.name)
                    sourceListRequest.predicate = NSCompoundPredicate(type: .or, subpredicates: [urlPredicate, infoPredicate])
                    sourceListRequest.fetchLimit = 1

                    if (try? backgroundContext.fetch(sourceListRequest).first) != nil {
                        continue
                    }

                    let newSourceList = SourceList(context: backgroundContext)
                    newSourceList.name = list.name
                    newSourceList.urlString = list.urlString
                    newSourceList.id = UUID(uuidString: list.id) ?? UUID()
                    newSourceList.author = list.author
                }
            }

            backupSourceNames = backup.sourceNames ?? []

            PersistenceController.shared.save(backgroundContext)

            // if iOS 14 is available, sleep to prevent any issues with alerts
            if #available(iOS 15, *) {
                showRestoreCompletedAlert.toggle()
            } else {
                Task {
                    try? await Task.sleep(seconds: 0.1)

                    Task { @MainActor in
                        showRestoreCompletedAlert.toggle()
                    }
                }
            }
        } catch {
            Task {
                await toastModel?.updateToastDescription("Backup restore: \(error)")
            }
        }
    }

    // Remove the backup from files and then the list
    // Removes an index if it's provided
    func removeBackup(backupUrl: URL, index: Int?) {
        do {
            try FileManager.default.removeItem(at: backupUrl)

            if let index = index {
                backupUrls.remove(at: index)
            } else {
                backupUrls.removeAll(where: { $0 == backupUrl })
            }
        } catch {
            Task {
                await toastModel?.updateToastDescription("Backup removal: \(error)")
            }
        }
    }

    func copyBackup(backupUrl: URL) {
        let backupSecured = backupUrl.startAccessingSecurityScopedResource()

        defer {
            if backupSecured {
                backupUrl.stopAccessingSecurityScopedResource()
            }
        }

        let backupsPath = FileManager.default.appDirectory.appendingPathComponent("Backups")
        let localBackupPath = backupsPath.appendingPathComponent(backupUrl.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: localBackupPath.path) {
                try FileManager.default.removeItem(at: localBackupPath)
            } else if !FileManager.default.fileExists(atPath: backupsPath.path) {
                try FileManager.default.createDirectory(atPath: backupsPath.path, withIntermediateDirectories: true, attributes: nil)
            }

            try FileManager.default.copyItem(at: backupUrl, to: localBackupPath)

            selectedBackupUrl = localBackupPath
        } catch {
            Task {
                await toastModel?.updateToastDescription("Backup copy: \(error)")
            }
        }
    }
}

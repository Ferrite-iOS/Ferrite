//
//  BackupModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/17/22.
//

import Foundation

public struct Backup: Codable {
    var bookmarks: [BookmarkJson]?
    var history: [HistoryJson]?
    var sourceNames: [String]?
    var sourceLists: [SourceListBackupJson]?
}

// MARK: - CoreData translation

typealias BookmarkJson = SearchResult

// Date is an epoch timestamp
struct HistoryJson: Codable {
    let dateString: String?
    let date: Double
    let entries: [HistoryEntryJson]
}

struct HistoryEntryJson: Codable {
    var name: String? = nil
    var subName: String? = nil
    var url: String? = nil
    var timeStamp: Double? = nil
    let source: String?
}

// Differs from SourceListJson
struct SourceListBackupJson: Codable {
    let name: String
    let author: String
    let id: String
    let urlString: String
}

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
    let name: String
    let subName: String?
    let url: String
    let timeStamp: Double?
    let source: String?
}

// Differs from SourceListJson
struct SourceListBackupJson: Codable {
    let name: String
    let author: String
    let id: String
    let urlString: String
}

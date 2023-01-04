//
//  BackupModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/17/22.
//

import Foundation

public struct Backup: Codable {
    let version: Int
    var bookmarks: [BookmarkJson]?
    var history: [HistoryJson]?
    var sourceNames: [String]?
    var sourceLists: [SourceListBackupJson]?
}

// MARK: - CoreData translation

// Don't typealias to search result as this is a reflection of CoreData's struct
struct BookmarkJson: Codable {
    let title: String?
    let source: String
    let size: String?
    let magnetLink: String?
    let magnetHash: String?
    let seeders: String?
    let leechers: String?
}

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

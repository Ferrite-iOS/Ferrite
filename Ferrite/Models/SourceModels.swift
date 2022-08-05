//
//  SourceModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import Foundation

public struct SourceListJson: Codable {
    let name: String
    let author: String
    var sources: [SourceJson]
}

public struct SourceJson: Codable, Hashable {
    let name: String
    let version: Int16
    let baseUrl: String
    var author: String?
    let rssParser: SourceRssParserJson?
    let htmlParser: SourceHtmlParserJson?
}

public enum SourcePreferredParser: Int16, CaseIterable {
    case none = 0
    case scraping = 1
    case rss = 2
    case siteApi = 3
}

public struct SourceRssParserJson: Codable, Hashable {
    let rssUrl: String?
    let searchUrl: String
    let items: String
    let magnetHash: SouceComplexQueryJson?
    let magnetLink: SouceComplexQueryJson?
    let title: SouceComplexQueryJson?
    let size: SouceComplexQueryJson?
    let sl: SourceSLJson?
    let trackers: [String]?
}

public struct SourceHtmlParserJson: Codable, Hashable {
    let searchUrl: String
    let rows: String
    let magnet: SourceMagnetJson
    let title: SouceComplexQueryJson?
    let size: SouceComplexQueryJson?
    let sl: SourceSLJson?
}

public struct SouceComplexQueryJson: Codable, Hashable {
    let query: String
    let lookupAttribute: String?
    let attribute: String?
    let regex: String?
}

public struct SourceMagnetJson: Codable, Hashable {
    let query: String
    let attribute: String
    let regex: String?
    let externalLinkQuery: String?
}

public struct SourceSLJson: Codable, Hashable {
    let seeders: String?
    let leechers: String?
    let combined: String?
    let attribute: String?
    let lookupAttribute: String?
    let seederRegex: String?
    let leecherRegex: String?
}

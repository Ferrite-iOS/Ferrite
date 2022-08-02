//
//  SourceModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import Foundation

public struct SourceListJson: Codable {
    let repoName: String?
    let repoAuthor: String?
    let sources: [SourceJson]

    enum CodingKeys: String, CodingKey {
        case repoName = "name"
        case repoAuthor = "author"
        case sources
    }
}

public struct SourceJson: Codable, Hashable {
    let name: String
    let version: String
    let baseUrl: String
    let htmlParser: SourceHtmlParserJson?
}

public struct SourceHtmlParserJson: Codable, Hashable {
    let searchUrl: String
    let rows: String
    let magnet: SourceMagnetJson
    let title: SouceComplexQuery?
    let size: SouceComplexQuery?
    let sl: SourceSLJson?
}

public struct SouceComplexQuery: Codable, Hashable {
    let query: String
    let attribute: String
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
    let attribute: String
    let seederRegex: String?
    let leecherRegex: String?
}

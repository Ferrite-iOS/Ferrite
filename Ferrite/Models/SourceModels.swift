//
//  SourceModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import Foundation

public struct SourceJson: Codable {
    let repoName: String?
    let repoAuthor: String?
    let sources: [TorrentSourceJson]

    enum CodingKeys: String, CodingKey {
        case repoName = "name"
        case repoAuthor = "author"
        case sources
    }
}

public struct TorrentSourceJson: Codable, Hashable {
    let name: String?
    let url: String
    let rowQuery: String
    let linkQuery: String
    let titleQuery: String?
    let sizeQuery: String?
}

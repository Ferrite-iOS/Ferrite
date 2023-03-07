//
//  SearchModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import Foundation

// A raw search result structure displayed on the UI
public struct SearchResult: Codable, Hashable, Sendable {
    let title: String?
    let source: String
    let size: String?
    let magnet: Magnet
    let seeders: String?
    let leechers: String?
}

extension ScrapingViewModel {
    // Contains both search results and magnet links for scalability
    struct SearchRequestResult: Sendable {
        let results: [SearchResult]
        let magnets: [Magnet]
    }

    struct ScrapingError: Error {}
}

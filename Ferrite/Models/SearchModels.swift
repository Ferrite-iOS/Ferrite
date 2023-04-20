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

    // Converts size to a double
    func rawSize() -> Double? {
        guard let size else {
            return nil
        }

        let splitSize = size.split(separator: " ")

        guard
            let bytesString = splitSize.first,
            let multipliedBytes = Double(bytesString),
            let units = splitSize.last
        else {
            return nil
        }

        switch units.lowercased() {
        case "gb":
            return multipliedBytes * 1e9
        case "gib":
            return multipliedBytes * pow(1024, 3)
        case "mb":
            return multipliedBytes * 1e6
        case "mib":
            return multipliedBytes * pow(1024, 2)
        case "kb":
            return multipliedBytes * 1e3
        case "kib":
            return multipliedBytes * 1024
        default:
            return nil
        }
    }
}

extension ScrapingViewModel {
    // Contains both search results and magnet links for scalability
    struct SearchRequestResult: Sendable {
        let results: [SearchResult]
        let magnets: [Magnet]
    }

    struct ScrapingError: Error {}
}

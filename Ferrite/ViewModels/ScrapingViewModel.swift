//
//  ScrapingViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/4/22.
//

import Base32
import SwiftSoup
import SwiftUI

public struct SearchResult: Hashable, Codable {
    let title: String
    let source: String
    let size: String
    let magnetLink: String
    let magnetHash: String?
}

class ScrapingViewModel: ObservableObject {
    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    // Link the toast view model for single-directional communication
    var toastModel: ToastViewModel?

    @Published var searchResults: [SearchResult] = []
    @Published var debridHashes: [String] = []
    @Published var searchText: String = ""
    @Published var selectedSearchResult: SearchResult?
    @Published var filteredSource: TorrentSource?

    @MainActor
    public func scanSources(sources: [TorrentSource]) async {
        if sources.isEmpty {
            print("Sources empty")
        }

        var tempResults: [SearchResult] = []

        for source in sources {
            if source.enabled {
                guard let html = await fetchWebsiteHtml(source: source) else {
                    continue
                }

                let sourceResults = await scrapeWebsite(source: source, html: html)
                tempResults += sourceResults
            }
        }

        searchResults = tempResults
    }

    // Fetches the HTML body for the source website
    @MainActor
    public func fetchWebsiteHtml(source: TorrentSource) async -> String? {
        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            toastModel?.toastDescription = "Could not process search query, invalid characters present."
            print("Could not process search query, invalid characters present")

            return nil
        }

        guard let url = URL(string: source.url + encodedQuery) else {
            toastModel?.toastDescription = "Source doesn't contain a valid URL, contact the source dev!"
            print("Source doesn't contain a valid URL, contact the source dev!")

            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .ascii)
            return html
        } catch {
            toastModel?.toastDescription = "Error in fetching HTML \(error)"
            print("Error in fetching HTML \(error)")

            return nil
        }
    }

    // Returns results to UI
    // Results must have a link and title, but other parameters aren't required
    @MainActor
    public func scrapeWebsite(source: TorrentSource, html: String) async -> [SearchResult] {
        var tempResults: [SearchResult] = []
        var hashes: [String] = []

        do {
            let document = try SwiftSoup.parse(html)

            let rows = try document.select(source.rowQuery)

            for row in rows {
                guard let link = try row.select(source.linkQuery).first() else {
                    continue
                }

                let href = try link.attr("href")

                if !href.starts(with: "magnet:") {
                    continue
                }

                let magnetHash = fetchMagnetHash(magnetLink: href)

                var title: String?
                if let titleQuery = source.titleQuery {
                    title = try row.select(titleQuery).first()?.text()
                }

                let size = try row.select(source.sizeQuery ?? "").first()
                let sizeText = try size?.text()

                let result = SearchResult(
                    title: title ?? "No title",
                    source: source.name ?? "N/A",
                    size: sizeText ?? "?B",
                    magnetLink: href,
                    magnetHash: magnetHash
                )

                // Change to bulk request to speed up UI
                if let hash = magnetHash {
                    hashes.append(hash)
                }

                tempResults.append(result)
            }

            return tempResults
        } catch {
            toastModel?.toastDescription = "Error while scraping: \(error)"
            print("Error while scraping: \(error)")

            return []
        }
    }

    // Fetches and possibly converts the magnet hash value to sha1
    public func fetchMagnetHash(magnetLink: String) -> String? {
        guard let firstSplit = magnetLink.split(separator: ":")[safe: 3] else {
            return nil
        }

        guard let magnetHash = firstSplit.split(separator: "&")[safe: 0] else {
            return nil
        }

        // Is this a Base32hex hash?
        if magnetHash.count == 32 {
            let decryptedMagnetHash = base32DecodeToData(String(magnetHash))
            return decryptedMagnetHash?.hexEncodedString()
        } else {
            return String(magnetHash)
        }
    }
}

//
//  ScrapingViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/4/22.
//

import Base32
import SwiftUI
import SwiftSoup

public struct SearchResult: Hashable, Codable {
    let title: String
    let source: String
    let size: String
    let magnetLink: String
    let magnetHash: String?
}

public struct TorrentSource: Hashable, Codable {
    let name: String
    let url: String
    let rowQuery: String
    let linkQuery: String
    let titleQuery: String
    let sizeQuery: String
}

class ScrapingViewModel: ObservableObject {
    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    // Link the toast view model for single-directional communication
    var toastModel: ToastViewModel? = nil

    // Decopule this in the future
    let sources = [
        //TorrentSource(
            //name: "Nyaa",
            //url: "https://nyaa.si",
            //rowQuery: ".torrent-list tbody tr",
            //linkQuery: "td:nth-child(3) > a:nth-child(2))",
            //titleQuery: "td:nth-child(2) > a:last-child"
        //),
        TorrentSource(
            name: "AnimeTosho",
            url: "https://animetosho.org/search?q=",
            rowQuery: "#content .home_list_entry",
            linkQuery: ".links > a:nth-child(4)",
            titleQuery: ".link",
            sizeQuery: ".size"
       )
    ]

    @Published var searchResults: [SearchResult] = []
    @Published var debridHashes: [String] = []
    @Published var searchText: String = ""
    @Published var selectedSearchResult: SearchResult?

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
    public func scrapeWebsite(source: TorrentSource, html: String) async {
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

                let title = try row.select(source.titleQuery).first()
                let titleText = try title?.text()

                let size = try row.select(source.sizeQuery).first()
                let sizeText = try size?.text()

                let result = SearchResult(
                    title: titleText ?? "No title provided",
                    source: source.name,
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

            searchResults = tempResults
        } catch {
            toastModel?.toastDescription = "Error while scraping: \(error)"
            print("Error while scraping: \(error)")
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

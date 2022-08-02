//
//  ScrapingViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/4/22.
//

import Base32
import Regex
import SwiftSoup
import SwiftUI

public struct SearchResult: Hashable, Codable {
    let title: String
    let source: String
    let size: String
    let magnetLink: String
    let magnetHash: String?
    let seeders: String?
    let leechers: String?
}

class ScrapingViewModel: ObservableObject {
    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    // Link the toast view model for single-directional communication
    var toastModel: ToastViewModel?

    @Published var searchResults: [SearchResult] = []
    @Published var searchText: String = ""
    @Published var selectedSearchResult: SearchResult?
    @Published var filteredSource: Source?

    @MainActor
    public func scanSources(sources: [Source]) async {
        if sources.isEmpty {
            print("Sources empty")
            return
        }

        var tempResults: [SearchResult] = []

        for source in sources {
            if source.enabled {
                if let htmlParser = source.htmlParser {
                    guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                        toastModel?.toastDescription = "Could not process search query, invalid characters present."
                        print("Could not process search query, invalid characters present")

                        continue
                    }

                    let urlString = source.baseUrl + htmlParser.searchUrl.replacingOccurrences(of: "{query}", with: encodedQuery)

                    guard let html = await fetchWebsiteHtml(urlString: urlString) else {
                        continue
                    }

                    let sourceResults = await scrapeWebsite(source: source, html: html)
                    tempResults += sourceResults
                }
            }
        }

        searchResults = tempResults
    }

    // Fetches the HTML for a URL
    @MainActor
    public func fetchWebsiteHtml(urlString: String) async -> String? {
        guard let url = URL(string: urlString) else {
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
    public func scrapeWebsite(source: Source, html: String) async -> [SearchResult] {
        guard let htmlParser = source.htmlParser else {
            return []
        }

        var rows = Elements()

        do {
            let document = try SwiftSoup.parse(html)
            rows = try document.select(htmlParser.rows)
        } catch {
            toastModel?.toastDescription = "Scraping error, couldn't fetch rows: \(error)"
            print("Scraping error, couldn't fetch rows: \(error)")

            return []
        }

        var tempResults: [SearchResult] = []

        // If there's an error, continue instead of returning with nothing
        for row in rows {
            do {
                // Fetches the magnet link
                // If the magnet is located on an external page, fetch the external page and grab the magnet link
                // External page fetching affects source performance
                guard let magnetParser = htmlParser.magnet else {
                    continue
                }

                var href: String
                if let externalMagnetQuery = magnetParser.externalLinkQuery, !externalMagnetQuery.isEmpty {
                    guard let externalMagnetLink = try row.select(externalMagnetQuery).first()?.attr("href") else {
                        continue
                    }

                    guard let magnetHtml = await fetchWebsiteHtml(urlString: source.baseUrl + externalMagnetLink) else {
                        continue
                    }

                    let magnetDocument = try SwiftSoup.parse(magnetHtml)
                    guard let linkResult = try magnetDocument.select(magnetParser.query).first() else {
                        continue
                    }

                    if magnetParser.attribute == "text" {
                        href = try linkResult.text()
                    } else {
                        href = try linkResult.attr(magnetParser.attribute)
                    }
                } else {
                    guard let link = try runComplexQuery(
                        row: row,
                        query: magnetParser.query,
                        attribute: magnetParser.attribute,
                        regexString: magnetParser.regex
                    ) else {
                        continue
                    }

                    href = link
                }

                if !href.starts(with: "magnet:") {
                    continue
                }

                // Fetches the magnet hash
                let magnetHash = fetchMagnetHash(magnetLink: href)

                // Fetches the episode/movie title
                var title: String?
                if let titleParser = htmlParser.title {
                    title = try? runComplexQuery(
                        row: row,
                        query: titleParser.query,
                        attribute: titleParser.attribute,
                        regexString: titleParser.regex
                    )
                }

                // Fetches the torrent's size
                var size: String?
                if let sizeParser = htmlParser.size {
                    size = try? runComplexQuery(
                        row: row,
                        query: sizeParser.query,
                        attribute: sizeParser.attribute,
                        regexString: sizeParser.regex
                    )
                }

                // Fetches seeders and leechers if there are any
                var seeders: String?
                var leechers: String?
                if let seederLeecher = htmlParser.seedLeech {
                    if let combinedQuery = seederLeecher.combined {
                        if let combinedString = try? runComplexQuery(
                            row: row,
                            query: combinedQuery,
                            attribute: seederLeecher.attribute,
                            regexString: nil
                        ) {
                            if let seederRegex = seederLeecher.seederRegex, let leecherRegex = seederLeecher.leecherRegex {
                                // Seeder regex matching
                                seeders = try? Regex(seederRegex).firstMatch(in: combinedString)?.groups[safe: 0]?.value

                                // Leecher regex matching
                                leechers = try? Regex(leecherRegex).firstMatch(in: combinedString)?.groups[safe: 0]?.value
                            }
                        }
                    } else {
                        if let seederQuery = seederLeecher.seeders {
                            seeders = try? runComplexQuery(
                                row: row,
                                query: seederQuery,
                                attribute: seederLeecher.attribute,
                                regexString: seederLeecher.seederRegex
                            )
                        }

                        if let leecherQuery = seederLeecher.seeders {
                            leechers = try? runComplexQuery(
                                row: row,
                                query: leecherQuery,
                                attribute: seederLeecher.attribute,
                                regexString: seederLeecher.leecherRegex
                            )
                        }
                    }
                }

                let result = SearchResult(
                    title: title ?? "No title",
                    source: source.name,
                    size: size ?? "",
                    magnetLink: href,
                    magnetHash: magnetHash,
                    seeders: seeders,
                    leechers: leechers
                )

                tempResults.append(result)
            } catch {
                toastModel?.toastDescription = "Scraping error: \(error)"
                print("Scraping error: \(error)")

                continue
            }
        }

        return tempResults
    }

    func runComplexQuery(row: Element, query: String, attribute: String, regexString: String?) throws -> String? {
        var parsedValue: String?

        let result = try row.select(query).first()

        switch attribute {
        case "text":
            parsedValue = try result?.text()
        default:
            parsedValue = try result?.attr(attribute)
        }

        // A capture group must be used in the provided regex
        if let regexString = regexString,
           let parsedValue = parsedValue,
           let regexValue = try Regex(regexString).firstMatch(in: parsedValue)?.groups[safe: 0]?.value
        {
            return regexValue
        } else {
            return parsedValue
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
            return String(magnetHash).lowercased()
        }
    }
}

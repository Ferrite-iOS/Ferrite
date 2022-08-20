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
    let byteCountFormatter: ByteCountFormatter = .init()

    @Published var runningSearchTask: Task<Void, Error>?
    @Published var searchResults: [SearchResult] = []
    @Published var searchText: String = ""
    @Published var selectedSearchResult: SearchResult?
    @Published var filteredSource: Source?
    @Published var currentSourceName: String?

    @MainActor
    public func scanSources(sources: [Source]) async {
        if sources.isEmpty {
            Task { @MainActor in
                toastModel?.toastType = .info
                toastModel?.toastDescription = "There are no sources to search!"
            }

            print("Sources empty")
            return
        }

        var tempResults: [SearchResult] = []

        for source in sources {
            if source.enabled {
                currentSourceName = source.name

                guard let baseUrl = source.baseUrl else {
                    Task { @MainActor in
                        toastModel?.toastDescription = "The base URL could not be found for source \(source.name)"
                    }

                    print("The base URL could not be found for source \(source.name)")
                    continue
                }

                // Default to HTML scraping
                let preferredParser = SourcePreferredParser(rawValue: source.preferredParser) ?? .none

                switch preferredParser {
                case .scraping:
                    if let htmlParser = source.htmlParser {
                        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                            toastModel?.toastDescription = "Could not process search query, invalid characters present."
                            print("Could not process search query, invalid characters present")

                            continue
                        }

                        let urlString = baseUrl + htmlParser.searchUrl.replacingOccurrences(of: "{query}", with: encodedQuery)

                        guard let html = await fetchWebsiteData(urlString: urlString) else {
                            continue
                        }

                        let sourceResults = await scrapeHtml(source: source, baseUrl: baseUrl, html: html)
                        tempResults += sourceResults
                    }
                case .rss:
                    if let rssParser = source.rssParser {
                        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                            toastModel?.toastDescription = "Could not process search query, invalid characters present."
                            print("Could not process search query, invalid characters present")

                            continue
                        }

                        let replacedSearchUrl = rssParser.searchUrl
                            .replacingOccurrences(of: "{apiKey}", with: source.api?.clientSecret ?? "")
                            .replacingOccurrences(of: "{query}", with: encodedQuery)

                        // If there is an RSS base URL, use that instead
                        var urlString: String
                        if let rssUrl = rssParser.rssUrl {
                            urlString = rssUrl + replacedSearchUrl
                        } else {
                            urlString = baseUrl + replacedSearchUrl
                        }

                        guard let rss = await fetchWebsiteData(urlString: urlString) else {
                            continue
                        }

                        let sourceResults = scrapeRss(source: source, rss: rss)
                        tempResults += sourceResults
                    }
                case .siteApi, .none:
                    continue
                }
            }
        }

        // If the task is cancelled, return
        if let searchTask = runningSearchTask, searchTask.isCancelled {
            return
        }

        searchResults = tempResults
    }

    // Fetches the data for a URL
    @MainActor
    public func fetchWebsiteData(urlString: String) async -> String? {
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
            let error = error as NSError

            switch error.code {
            case -999:
                toastModel?.toastType = .info
                toastModel?.toastDescription = "Search cancelled"
            default:
                toastModel?.toastDescription = "Error in fetching data \(error)"
            }

            print("Error in fetching data \(error)")

            return nil
        }
    }

    // RSS feed scraper
    @MainActor
    public func scrapeRss(source: Source, rss: String) -> [SearchResult] {
        var tempResults: [SearchResult] = []

        guard let rssParser = source.rssParser else {
            return tempResults
        }

        var items = Elements()

        do {
            let document = try SwiftSoup.parse(rss, "", Parser.xmlParser())
            items = try document.getElementsByTag("item")
        } catch {
            toastModel?.toastDescription = "RSS scraping error, couldn't fetch items: \(error)"
            print("RSS scraping error, couldn't fetch items: \(error)")

            return tempResults
        }

        for item in items {
            // Parse magnet link or translate hash
            var magnetHash: String?
            if let magnetHashParser = rssParser.magnetHash {
                magnetHash = try? runRssComplexQuery(
                    item: item,
                    query: magnetHashParser.query,
                    attribute: magnetHashParser.attribute,
                    lookupAttribute: magnetHashParser.lookupAttribute,
                    regexString: magnetHashParser.regex
                )
            }

            var title: String?
            if let titleParser = rssParser.title {
                title = try? runRssComplexQuery(
                    item: item,
                    query: titleParser.query,
                    attribute: titleParser.attribute,
                    lookupAttribute: titleParser.lookupAttribute,
                    regexString: titleParser.regex
                )
            }

            var link: String?
            if let magnetLinkParser = rssParser.magnetLink {
                link = try? runRssComplexQuery(
                    item: item,
                    query: magnetLinkParser.query,
                    attribute: magnetLinkParser.attribute,
                    lookupAttribute: magnetLinkParser.lookupAttribute,
                    regexString: magnetLinkParser.regex
                )
            } else if let magnetHash = magnetHash {
                link = generateMagnetLink(magnetHash: magnetHash, title: title, trackers: rssParser.trackers)
            } else {
                continue
            }

            guard let href = link, href.starts(with: "magnet:") else {
                continue
            }

            if magnetHash == nil {
                magnetHash = fetchMagnetHash(magnetLink: href)
            }

            var size: String?
            if let sizeParser = rssParser.size {
                size = try? runRssComplexQuery(
                    item: item,
                    query: sizeParser.query,
                    attribute: sizeParser.attribute,
                    lookupAttribute: sizeParser.lookupAttribute,
                    regexString: sizeParser.regex
                )
            }

            if let sizeString = size, let sizeInt = Int64(sizeString) {
                size = byteCountFormatter.string(fromByteCount: sizeInt)
            }

            var seeders: String?
            var leechers: String?
            if let seederLeecher = rssParser.seedLeech {
                if let seederQuery = seederLeecher.seeders {
                    seeders = try? runRssComplexQuery(
                        item: item,
                        query: seederQuery,
                        attribute: seederLeecher.attribute,
                        lookupAttribute: seederLeecher.lookupAttribute,
                        regexString: seederLeecher.seederRegex
                    )
                }

                if let leecherQuery = seederLeecher.leechers {
                    leechers = try? runRssComplexQuery(
                        item: item,
                        query: leecherQuery,
                        attribute: seederLeecher.attribute,
                        lookupAttribute: seederLeecher.lookupAttribute,
                        regexString: seederLeecher.leecherRegex
                    )
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

            if !tempResults.contains(result) {
                tempResults.append(result)
            }
        }

        return tempResults
    }

    // HTML scraper
    @MainActor
    public func scrapeHtml(source: Source, baseUrl: String, html: String) async -> [SearchResult] {
        var tempResults: [SearchResult] = []

        guard let htmlParser = source.htmlParser else {
            return tempResults
        }

        var rows = Elements()

        do {
            let document = try SwiftSoup.parse(html)
            rows = try document.select(htmlParser.rows)
        } catch {
            toastModel?.toastDescription = "Scraping error, couldn't fetch rows: \(error)"
            print("Scraping error, couldn't fetch rows: \(error)")

            return tempResults
        }

        // If there's an error, continue instead of returning with nothing
        for row in rows {
            do {
                // Fetches the magnet link
                // If the magnet is located on an external page, fetch the external page and grab the magnet link
                // External page fetching affects source performance
                guard let magnetParser = htmlParser.magnetLink else {
                    continue
                }

                var href: String
                if let externalMagnetQuery = magnetParser.externalLinkQuery, !externalMagnetQuery.isEmpty {
                    guard let externalMagnetLink = try row.select(externalMagnetQuery).first()?.attr("href") else {
                        continue
                    }

                    guard let magnetHtml = await fetchWebsiteData(urlString: baseUrl + externalMagnetLink) else {
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
                    guard let link = try runHtmlComplexQuery(
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
                    title = try? runHtmlComplexQuery(
                        row: row,
                        query: titleParser.query,
                        attribute: titleParser.attribute,
                        regexString: titleParser.regex
                    )
                }

                // Fetches the torrent's size
                // TODO: Add int translation
                var size: String?
                if let sizeParser = htmlParser.size {
                    size = try? runHtmlComplexQuery(
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
                        if let combinedString = try? runHtmlComplexQuery(
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
                            seeders = try? runHtmlComplexQuery(
                                row: row,
                                query: seederQuery,
                                attribute: seederLeecher.attribute,
                                regexString: seederLeecher.seederRegex
                            )
                        }

                        if let leecherQuery = seederLeecher.seeders {
                            leechers = try? runHtmlComplexQuery(
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

                if !tempResults.contains(result) {
                    tempResults.append(result)
                }
            } catch {
                toastModel?.toastDescription = "Scraping error: \(error)"
                print("Scraping error: \(error)")

                continue
            }
        }

        return tempResults
    }

    // Complex query parsing for HTML scraping
    func runHtmlComplexQuery(row: Element, query: String, attribute: String, regexString: String?) throws -> String? {
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
           let regexValue = try? Regex(regexString).firstMatch(in: parsedValue)?.groups[safe: 0]?.value
        {
            return regexValue
        } else {
            return parsedValue
        }
    }

    // Complex query parsing for RSS scraping
    func runRssComplexQuery(item: Element, query: String, attribute: String, lookupAttribute: String?, regexString: String?) throws -> String? {
        var parsedValue: String?

        switch attribute {
        case "text":
            parsedValue = try item.getElementsByTag(query).first()?.text()
        default:
            // If there's a key/value to lookup the attribute with, query it. Othewise assume the value is in the same attribute
            if let lookupAttribute = lookupAttribute {
                let containerElement = try item.getElementsByAttributeValue(lookupAttribute, query).first()
                parsedValue = try containerElement?.attr(attribute)
            } else {
                let containerElement = try item.getElementsByAttribute(attribute).first()
                parsedValue = try containerElement?.attr(attribute)
            }
        }

        // A capture group must be used in the provided regex
        if let regexString = regexString,
           let parsedValue = parsedValue,
           let regexValue = try? Regex(regexString).firstMatch(in: parsedValue)?.groups[safe: 0]?.value
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

    func parseSizeString(sizeString: String) -> String? {
        // Test if the string can be a full integer
        guard let size = Int(sizeString) else {
            return nil
        }

        let length = sizeString.count

        if length > 9 {
            // This is a GB
            return String("\(Double(size) / 1e9) GB")
        } else if length > 6 {
            // This is a MB
            return String("\(Double(size) / 1e6) MB")
        } else if length > 3 {
            // This is a KB
            return String("\(Double(size) / 1e3) KB")
        } else {
            return nil
        }
    }

    public func generateMagnetLink(magnetHash: String, title: String?, trackers: [String]?) -> String {
        var magnetLinkArray = ["magnet:?xt=urn:btih:"]

        magnetLinkArray.append(magnetHash)

        if let title = title, let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            magnetLinkArray.append("&dn=\(encodedTitle)")
        }

        if let trackers = trackers {
            for trackerUrl in trackers {
                if URL(string: trackerUrl) != nil,
                   let encodedUrlString = trackerUrl.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                {
                    magnetLinkArray.append("&tr=\(encodedUrlString)")
                }
            }
        }

        return magnetLinkArray.joined()
    }
}

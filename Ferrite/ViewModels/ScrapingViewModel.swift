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
import SwiftyJSON

public struct SearchResult: Hashable, Codable {
    let title: String?
    let source: String
    let size: String?
    let magnetLink: String?
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
    func updateSearchResults(newResults: [SearchResult]) {
        searchResults = newResults
    }

    public func scanSources(sources: [Source]) async {
        if sources.isEmpty {
            await toastModel?.updateToastDescription("There are no sources to search!", newToastType: .info)

            print("There are no sources to search!")
            return
        }

        var tempResults: [SearchResult] = []

        for source in sources {
            if source.enabled {
                Task { @MainActor in
                    currentSourceName = source.name
                }

                guard let baseUrl = source.baseUrl else {
                    await toastModel?.updateToastDescription("The base URL could not be found for source \(source.name)")

                    print("The base URL could not be found for source \(source.name)")
                    continue
                }

                // Default to HTML scraping
                let preferredParser = SourcePreferredParser(rawValue: source.preferredParser) ?? .none

                guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    await toastModel?.updateToastDescription("Could not process search query, invalid characters present.")
                    print("Could not process search query, invalid characters present")

                    continue
                }

                switch preferredParser {
                case .scraping:
                    if let htmlParser = source.htmlParser {
                        let replacedSearchUrl = htmlParser.searchUrl
                            .replacingOccurrences(of: "{query}", with: encodedQuery)

                        let data = await handleUrls(
                            baseUrl: baseUrl,
                            replacedSearchUrl: replacedSearchUrl,
                            fallbackUrls: source.fallbackUrls
                        )

                        if let data = data,
                           let html = String(data: data, encoding: .utf8)
                        {
                            let sourceResults = await scrapeHtml(source: source, baseUrl: baseUrl, html: html)
                            tempResults += sourceResults
                        }
                    }
                case .rss:
                    if let rssParser = source.rssParser {
                        let replacedSearchUrl = rssParser.searchUrl
                            .replacingOccurrences(of: "{secret}", with: source.api?.clientSecret?.value ?? "")
                            .replacingOccurrences(of: "{query}", with: encodedQuery)

                        // Do not use fallback URLs if the base URL isn't used
                        let data: Data?
                        if let rssUrl = rssParser.rssUrl {
                            data = await fetchWebsiteData(urlString: rssUrl + replacedSearchUrl)
                        } else {
                            data = await handleUrls(
                                baseUrl: baseUrl,
                                replacedSearchUrl: replacedSearchUrl,
                                fallbackUrls: source.fallbackUrls
                            )
                        }

                        if let data = data,
                           let rss = String(data: data, encoding: .utf8)
                        {
                            let sourceResults = await scrapeRss(source: source, rss: rss)
                            tempResults += sourceResults
                        }
                    }
                case .siteApi:
                    if let jsonParser = source.jsonParser {
                        var replacedSearchUrl = jsonParser.searchUrl
                            .replacingOccurrences(of: "{query}", with: encodedQuery)

                        // Handle anything API related including tokens, client IDs, and appending the API URL
                        // The source API key is for APIs that require extra credentials or use a different URL
                        if let sourceApi = source.api {
                            if let clientIdInfo = sourceApi.clientId {
                                if let newSearchUrl = await handleApiCredential(clientIdInfo,
                                                                                replacement: "{clientId}",
                                                                                searchUrl: replacedSearchUrl,
                                                                                apiUrl: sourceApi.apiUrl,
                                                                                baseUrl: baseUrl)
                                {
                                    replacedSearchUrl = newSearchUrl
                                }
                            }

                            // Works exactly the same as the client ID check
                            if let clientSecretInfo = sourceApi.clientSecret {
                                if let newSearchUrl = await handleApiCredential(clientSecretInfo,
                                                                                replacement: "{secret}",
                                                                                searchUrl: replacedSearchUrl,
                                                                                apiUrl: sourceApi.apiUrl,
                                                                                baseUrl: baseUrl)
                                {
                                    replacedSearchUrl = newSearchUrl
                                }
                            }
                        }

                        let passedUrl = source.api?.apiUrl ?? baseUrl
                        let data = await handleUrls(
                            baseUrl: passedUrl,
                            replacedSearchUrl: replacedSearchUrl,
                            fallbackUrls: source.fallbackUrls
                        )

                        if let data = data {
                            let sourceResults = await scrapeJson(source: source, jsonData: data)
                            tempResults += sourceResults
                        }
                    }
                case .none:
                    continue
                }
            }
        }

        // If the task is cancelled, return
        if let searchTask = runningSearchTask, searchTask.isCancelled {
            return
        }

        await updateSearchResults(newResults: tempResults)
    }

    // Checks the base URL for any website data then iterates through the fallback URLs
    func handleUrls(baseUrl: String, replacedSearchUrl: String, fallbackUrls: [String]?) async -> Data? {
        if let data = await fetchWebsiteData(urlString: baseUrl + replacedSearchUrl) {
            return data
        }

        if let fallbackUrls = fallbackUrls {
            for fallbackUrl in fallbackUrls {
                if let data = await fetchWebsiteData(urlString: fallbackUrl + replacedSearchUrl) {
                    return data
                }
            }
        }

        return nil
    }

    public func handleApiCredential(_ credential: SourceApiCredential,
                                    replacement: String,
                                    searchUrl: String,
                                    apiUrl: String?,
                                    baseUrl: String) async -> String?
    {
        // Is the credential expired
        var isExpired = false
        if let timeStamp = credential.timeStamp?.timeIntervalSince1970, credential.expiryLength != 0 {
            let now = Date().timeIntervalSince1970

            isExpired = now > timeStamp + credential.expiryLength
        }

        // Fetch a new credential if it's expired or doesn't exist yet
        if let value = credential.value, !isExpired {
            return searchUrl
                .replacingOccurrences(of: replacement, with: value)
        } else if
            credential.value == nil || isExpired,
            let credentialUrl = credential.urlString,
            let newValue = await fetchApiCredential(
                urlString: (apiUrl ?? baseUrl) + credentialUrl,
                credential: credential
            )
        {
            let backgroundContext = PersistenceController.shared.backgroundContext

            credential.value = newValue
            credential.timeStamp = Date()

            PersistenceController.shared.save(backgroundContext)

            return searchUrl
                .replacingOccurrences(of: replacement, with: newValue)
        }

        return nil
    }

    public func fetchApiCredential(urlString: String, credential: SourceApiCredential) async -> String? {
        guard let url = URL(string: urlString) else {
            Task { @MainActor in
                toastModel?.updateToastDescription("This token URL is invalid.")
            }
            print("Token url \(urlString) is invalid!")

            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let responseType = ApiCredentialResponseType(rawValue: credential.responseType ?? "") ?? .json

            switch responseType {
            case .json:
                guard let credentialQuery = credential.query else {
                    return nil
                }

                let json = try JSON(data: data)

                return json[credentialQuery.components(separatedBy: ".")].string
            case .text:
                return String(data: data, encoding: .utf8)
            }
        } catch {
            let error = error as NSError

            switch error.code {
            case -999:
                await toastModel?.updateToastDescription("Search cancelled", newToastType: .info)
            case -1001:
                await toastModel?.updateToastDescription("Credentials request timed out")
            default:
                await toastModel?.updateToastDescription("Error in fetching an API credential \(error)")
            }

            print("Error in fetching an API credential \(error)")

            return nil
        }
    }

    // Fetches the data for a URL
    public func fetchWebsiteData(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else {
            await toastModel?.updateToastDescription("Source doesn't contain a valid URL, contact the source dev!")

            print("Source doesn't contain a valid URL, contact the source dev!")

            return nil
        }

        let request = URLRequest(url: url, timeoutInterval: 15)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            let error = error as NSError

            switch error.code {
            case -999:
                await toastModel?.updateToastDescription("Search cancelled", newToastType: .info)
            case -1001:
                await toastModel?.updateToastDescription("Data request timed out. Trying fallback URLs if present.")
            default:
                await toastModel?.updateToastDescription("Error in fetching website data \(error)")
            }

            print("Error in fetching data \(error)")

            return nil
        }
    }

    public func scrapeJson(source: Source, jsonData: Data) async -> [SearchResult] {
        var tempResults: [SearchResult] = []

        guard let jsonParser = source.jsonParser else {
            return tempResults
        }

        var jsonResults: [JSON] = []

        do {
            let json = try JSON(data: jsonData)

            if let resultsQuery = jsonParser.results {
                jsonResults = json[resultsQuery.components(separatedBy: ".")].arrayValue
            } else {
                jsonResults = json.arrayValue
            }
        } catch {
            if let api = source.api {
                await cleanApiCreds(api: api)

                print("JSON parsing error, couldn't fetch results: \(error)")
            }
        }

        // If there are no results and the client secret isn't dynamic, just clear out the token
        if let api = source.api, jsonResults.isEmpty {
            await cleanApiCreds(api: api)

            print("JSON results were empty!")
        }

        // Iterate through results and grab what we can
        for result in jsonResults {
            var subResults: [JSON] = []

            let searchResult = parseJsonResult(result, jsonParser: jsonParser, source: source)

            // If subresults exist, iterate through those as well with the existing result
            // Otherwise append the applied result if it exists
            // Better to be redundant with checks rather than another for loop or filter
            if let subResultsQuery = jsonParser.subResults {
                subResults = result[subResultsQuery.components(separatedBy: ".")].arrayValue

                for subResult in subResults {
                    if let newSearchResult =
                        parseJsonResult(
                            subResult,
                            jsonParser: jsonParser,
                            source: source,
                            existingSearchResult: searchResult
                        ),
                        let magnetLink = newSearchResult.magnetLink,
                        magnetLink.starts(with: "magnet:"),
                        !tempResults.contains(newSearchResult)
                    {
                        tempResults.append(newSearchResult)
                    }
                }
            } else if
                let searchResult = searchResult,
                let magnetLink = searchResult.magnetLink,
                magnetLink.starts(with: "magnet:"),
                !tempResults.contains(searchResult)
            {
                tempResults.append(searchResult)
            }
        }

        return tempResults
    }

    public func parseJsonResult(_ result: JSON, jsonParser: SourceJsonParser, source: Source, existingSearchResult: SearchResult? = nil) -> SearchResult? {
        var magnetHash: String? = existingSearchResult?.magnetHash

        if let magnetHashParser = jsonParser.magnetHash {
            let rawHash = result[magnetHashParser.query.components(separatedBy: ".")].rawValue

            if !(rawHash is NSNull) {
                magnetHash = fetchMagnetHash(existingHash: String(describing: rawHash))
            }
        }

        var title: String? = existingSearchResult?.title

        if let titleParser = jsonParser.title {
            if let existingTitle = existingSearchResult?.title,
               let discriminatorQuery = titleParser.discriminator
            {
                let rawDiscriminator = result[discriminatorQuery.components(separatedBy: ".")].rawValue

                if !(rawDiscriminator is NSNull) {
                    title = String(describing: rawDiscriminator) + existingTitle
                }
            } else if existingSearchResult?.title == nil {
                let rawTitle = result[titleParser.query].rawValue
                title = rawTitle is NSNull ? nil : String(describing: rawTitle)
            }
        }

        var link: String? = existingSearchResult?.magnetLink

        if let magnetLinkParser = jsonParser.magnetLink, existingSearchResult?.magnetLink == nil {
            let rawLink = result[magnetLinkParser.query.components(separatedBy: ".")].rawValue
            link = rawLink is NSNull ? nil : String(describing: rawLink)
        } else if let magnetHash = magnetHash {
            link = generateMagnetLink(magnetHash: magnetHash, title: title, trackers: source.trackers)
        }

        if magnetHash == nil, let href = link {
            magnetHash = fetchMagnetHash(magnetLink: href)
        }

        var size: String? = existingSearchResult?.size

        if let sizeParser = jsonParser.size, existingSearchResult?.size == nil {
            let rawSize = result[sizeParser.query.components(separatedBy: ".")].rawValue
            size = rawSize is NSNull ? nil : String(describing: rawSize)
        }

        if let sizeString = size, let sizeInt = Int64(sizeString) {
            size = byteCountFormatter.string(fromByteCount: sizeInt)
        }

        var seeders: String? = existingSearchResult?.seeders
        var leechers: String? = existingSearchResult?.leechers

        if let seederLeecher = jsonParser.seedLeech {
            if let seederQuery = seederLeecher.seeders, existingSearchResult?.seeders == nil {
                let rawSeeders = result[seederQuery.components(separatedBy: ".")].rawValue
                seeders = rawSeeders is NSNull ? nil : String(describing: rawSeeders)
            }

            if let leecherQuery = seederLeecher.leechers, existingSearchResult?.leechers == nil {
                let rawLeechers = result[leecherQuery.components(separatedBy: ".")].rawValue
                leechers = rawLeechers is NSNull ? nil : String(describing: rawLeechers)
            }
        }

        let result = SearchResult(
            title: title,
            source: source.name,
            size: size,
            magnetLink: link,
            magnetHash: magnetHash,
            seeders: seeders,
            leechers: leechers
        )

        return result
    }

    // RSS feed scraper
    public func scrapeRss(source: Source, rss: String) async -> [SearchResult] {
        var tempResults: [SearchResult] = []

        guard let rssParser = source.rssParser else {
            return tempResults
        }

        var items = Elements()

        do {
            let document = try SwiftSoup.parse(rss, "", Parser.xmlParser())
            items = try document.getElementsByTag("item")
        } catch {
            await toastModel?.updateToastDescription("RSS scraping error, couldn't fetch items: \(error)")
            print("RSS scraping error, couldn't fetch items: \(error)")

            return tempResults
        }

        for item in items {
            // Parse magnet link or translate hash
            var magnetHash: String?
            if let magnetHashParser = rssParser.magnetHash {
                let tempHash = try? runRssComplexQuery(
                    item: item,
                    query: magnetHashParser.query,
                    attribute: magnetHashParser.attribute,
                    discriminator: magnetHashParser.discriminator,
                    regexString: magnetHashParser.regex
                )

                magnetHash = fetchMagnetHash(existingHash: tempHash)
            }

            var title: String?
            if let titleParser = rssParser.title {
                title = try? runRssComplexQuery(
                    item: item,
                    query: titleParser.query,
                    attribute: titleParser.attribute,
                    discriminator: titleParser.discriminator,
                    regexString: titleParser.regex
                )
            }

            var link: String?
            if let magnetLinkParser = rssParser.magnetLink {
                link = try? runRssComplexQuery(
                    item: item,
                    query: magnetLinkParser.query,
                    attribute: magnetLinkParser.attribute,
                    discriminator: magnetLinkParser.discriminator,
                    regexString: magnetLinkParser.regex
                )
            } else if let magnetHash = magnetHash {
                link = generateMagnetLink(magnetHash: magnetHash, title: title, trackers: source.trackers)
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
                    discriminator: sizeParser.discriminator,
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
                        discriminator: seederLeecher.discriminator,
                        regexString: seederLeecher.seederRegex
                    )
                }

                if let leecherQuery = seederLeecher.leechers {
                    leechers = try? runRssComplexQuery(
                        item: item,
                        query: leecherQuery,
                        attribute: seederLeecher.attribute,
                        discriminator: seederLeecher.discriminator,
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

    // Complex query parsing for RSS scraping
    func runRssComplexQuery(item: Element, query: String, attribute: String, discriminator: String?, regexString: String?) throws -> String? {
        var parsedValue: String?

        switch attribute {
        case "text":
            parsedValue = try item.getElementsByTag(query).first()?.text()
        default:
            // If there's a key/value to lookup the attribute with, query it. Othewise assume the value is in the same attribute
            if let discriminator = discriminator {
                let containerElement = try item.getElementsByAttributeValue(discriminator, query).first()
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

    // HTML scraper
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
            await toastModel?.updateToastDescription("Scraping error, couldn't fetch rows: \(error)")
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
                    guard
                        let externalMagnetLink = try row.select(externalMagnetQuery).first()?.attr("href"),
                        let data = await fetchWebsiteData(urlString: baseUrl + externalMagnetLink),
                        let magnetHtml = String(data: data, encoding: .utf8)
                    else {
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
                await toastModel?.updateToastDescription("Scraping error: \(error)")
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

    // Fetches and possibly converts the magnet hash value to sha1
    public func fetchMagnetHash(magnetLink: String? = nil, existingHash: String? = nil) -> String? {
        var magnetHash: String

        if let existingHash = existingHash {
            magnetHash = existingHash
        } else if
            let magnetLink = magnetLink,
            let firstSplit = magnetLink.split(separator: ":")[safe: 3],
            let tempHash = firstSplit.split(separator: "&")[safe: 0]
        {
            magnetHash = String(tempHash)
        } else {
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

    func cleanApiCreds(api: SourceApi) async {
        let backgroundContext = PersistenceController.shared.backgroundContext

        let hasCredentials = api.clientId != nil || api.clientSecret != nil
        let clientIdReset: Bool
        let clientSecretReset: Bool

        var responseArray = ["Could not fetch API results"]

        if let clientId = api.clientId, !clientId.dynamic {
            clientId.value = nil
            clientIdReset = true
        } else {
            clientIdReset = false
        }

        if let clientSecret = api.clientSecret, !clientSecret.dynamic {
            clientSecret.value = nil
            clientSecretReset = true
        } else {
            clientSecretReset = false
        }

        if hasCredentials {
            responseArray.append("your")

            if clientIdReset {
                responseArray.append("client ID")
            }

            if clientIdReset, clientSecretReset {
                responseArray.append("and")
            }

            if clientSecretReset {
                responseArray.append("token")
            }

            responseArray.append("was automatically reset.")

            if !(clientIdReset || clientSecretReset) {
                responseArray.append("Make sure all credentials are correct in the source's settings!")
            }
        }

        await toastModel?.updateToastDescription(responseArray.joined())

        PersistenceController.shared.save(backgroundContext)
    }
}

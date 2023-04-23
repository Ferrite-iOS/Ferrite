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

class ScrapingViewModel: ObservableObject {
    // Link the toast view model for single-directional communication
    var logManager: LoggingManager?
    let byteCountFormatter: ByteCountFormatter = .init()

    var runningSearchTask: Task<Void, Error>?
    func cancelCurrentTask() {
        runningSearchTask?.cancel()
        runningSearchTask = nil
    }

    var cleanedSearchText: String = ""
    @Published var searchResults: [SearchResult] = []

    // Only add results with valid magnet hashes to the search results array
    @MainActor
    func updateSearchResults(newResults: [SearchResult]) {
        searchResults += newResults
    }

    @MainActor
    func clearSearchResults() {
        searchResults = []
    }

    @Published var currentSourceNames: Set<String> = []
    @MainActor
    func updateCurrentSourceNames(_ newName: String) {
        currentSourceNames.insert(newName)
        logManager?.updateIndeterminateToast(
            "Loading \(currentSourceNames.joined(separator: ", "))",
            cancelAction: nil
        )
    }

    @MainActor
    func removeCurrentSourceName(_ removedName: String) {
        currentSourceNames.remove(removedName)
        logManager?.updateIndeterminateToast(
            "Loading \(currentSourceNames.joined(separator: ", "))",
            cancelAction: nil
        )
    }

    @MainActor
    func clearCurrentSourceNames() {
        currentSourceNames = []
        logManager?.updateIndeterminateToast("Loading sources", cancelAction: nil)
    }

    // Utility function to print source specific errors
    func sendSourceError(_ description: String) async {
        await logManager?.error(description, showToast: false)
    }

    public func scanSources(sources: [Source], searchText: String, debridManager: DebridManager) async {
        await logManager?.info("Started scanning sources for query \"\(searchText)\"")

        if sources.isEmpty {
            await logManager?.info(
                "ScrapingModel: No sources found",
                description: "There are no sources to search!"
            )

            return
        }

        cleanedSearchText = searchText.lowercased()

        if await !debridManager.enabledDebrids.isEmpty {
            await debridManager.clearIAValues()
        }

        await clearCurrentSourceNames()
        await clearSearchResults()

        await logManager?.updateIndeterminateToast("Loading sources", cancelAction: {
            self.cancelCurrentTask()
        })

        // Run all tasks in parallel for speed
        await withTaskGroup(of: (SearchRequestResult?, String).self) { group in
            // TODO: Maybe chunk sources to groups of 5 to not overwhelm the app
            for source in sources {
                // If the search is cancelled, return
                if let runningSearchTask, runningSearchTask.isCancelled {
                    return
                }

                if source.enabled {
                    group.addTask {
                        await self.updateCurrentSourceNames(source.name)
                        let requestResult = await self.executeParser(source: source)

                        return (requestResult, source.name)
                    }
                }
            }

            // Let the user know that there was an error in the source
            var failedSourceNames: [String] = []
            for await (requestResult, sourceName) in group {
                if let requestResult {
                    if await !debridManager.enabledDebrids.isEmpty {
                        await debridManager.populateDebridIA(requestResult.magnets)
                    }

                    await self.updateSearchResults(newResults: requestResult.results)
                } else {
                    failedSourceNames.append(sourceName)
                }

                await removeCurrentSourceName(sourceName)
            }

            if !failedSourceNames.isEmpty {
                let joinedSourceNames = failedSourceNames.joined(separator: ", ")
                await logManager?.info(
                    "Scraping: Errors in sources \(joinedSourceNames). See above.",
                    description: "There were errors in sources \(joinedSourceNames). Check the logs for more details."
                )
            }
        }

        await clearCurrentSourceNames()
        await logManager?.info("Source scan finished")

        // If the search is cancelled, return
        if let searchTask = runningSearchTask, searchTask.isCancelled {
            return
        }
    }

    func executeParser(source: Source) async -> SearchRequestResult? {
        guard let website = source.website else {
            await logManager?.error("Scraping: The base URL could not be found for source \(source.name)")

            return nil
        }

        // Default to HTML scraping
        let preferredParser = SourcePreferredParser(rawValue: source.preferredParser) ?? .none

        guard let encodedQuery = cleanedSearchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            await sendSourceError("\(source.name): Could not process search query, invalid characters present.")

            return nil
        }

        switch preferredParser {
        case .scraping:
            if let htmlParser = source.htmlParser {
                let replacedSearchUrl = htmlParser.searchUrl.map {
                    $0.replacingOccurrences(of: "{query}", with: encodedQuery)
                }

                let data = await handleUrls(
                    website: website,
                    replacedSearchUrl: replacedSearchUrl,
                    fallbackUrls: source.fallbackUrls,
                    sourceName: source.name
                )

                if let data,
                   let html = String(data: data, encoding: .utf8)
                {
                    return await scrapeHtml(source: source, website: website, html: html)
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
                    data = await fetchWebsiteData(
                        urlString: rssUrl + replacedSearchUrl,
                        sourceName: source.name
                    )
                } else {
                    data = await handleUrls(
                        website: website,
                        replacedSearchUrl: replacedSearchUrl,
                        fallbackUrls: source.fallbackUrls,
                        sourceName: source.name
                    )
                }

                if let data,
                   let rss = String(data: data, encoding: .utf8)
                {
                    return await scrapeRss(source: source, rss: rss)
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
                                                                        website: website,
                                                                        sourceName: source.name)
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
                                                                        website: website,
                                                                        sourceName: source.name)
                        {
                            replacedSearchUrl = newSearchUrl
                        }
                    }
                }

                let passedUrl = source.api?.apiUrl ?? website
                let data = await handleUrls(
                    website: passedUrl,
                    replacedSearchUrl: replacedSearchUrl,
                    fallbackUrls: source.fallbackUrls,
                    sourceName: source.name
                )

                if let data {
                    return await scrapeJson(source: source, jsonData: data)
                }
            }
        case .none:
            return nil
        }

        return nil
    }

    // Checks the base URL for any website data then iterates through the fallback URLs
    func handleUrls(website: String, replacedSearchUrl: String?, fallbackUrls: [String]?, sourceName: String) async -> Data? {
        let fetchUrl = website + (replacedSearchUrl.map { $0 } ?? "")
        if let data = await fetchWebsiteData(urlString: fetchUrl, sourceName: sourceName) {
            return data
        }

        if let fallbackUrls {
            for fallbackUrl in fallbackUrls {
                let fetchUrl = fallbackUrl + (replacedSearchUrl.map { $0 } ?? "")
                if let data = await fetchWebsiteData(urlString: fetchUrl, sourceName: sourceName) {
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
                                    website: String,
                                    sourceName: String) async -> String?
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
                urlString: (apiUrl ?? website) + credentialUrl,
                credential: credential,
                sourceName: sourceName
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

    public func fetchApiCredential(urlString: String,
                                   credential: SourceApiCredential,
                                   sourceName: String) async -> String?
    {
        guard let url = URL(string: urlString) else {
            await sendSourceError("\(sourceName): Token URL \(urlString) is invalid.")

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
                await logManager?.info("Scraping: Search cancelled")
            case -1001:
                await sendSourceError("\(sourceName): Credentials request timed out")
            case -1009:
                await logManager?.info("\(sourceName): The connection is offline")
            default:
                await sendSourceError("\(sourceName): Error in fetching an API credential \(error)")
            }

            return nil
        }
    }

    // Fetches the data for a URL
    public func fetchWebsiteData(urlString: String, sourceName: String) async -> Data? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            await sendSourceError("\(sourceName): Source doesn't contain a valid URL, contact the source dev!")

            return nil
        }

        var timeout: Double = 15

        let disableRequestTimeout = UserDefaults.standard.bool(forKey: "Behavior.DisableRequestTimeout")
        if disableRequestTimeout {
            timeout = Double.infinity
        } else {
            let requestTimeoutSecs = UserDefaults.standard.double(forKey: "Behavior.RequestTimeoutSecs")
            if requestTimeoutSecs != 0 {
                timeout = requestTimeoutSecs
            }
        }

        let request = URLRequest(url: url, timeoutInterval: timeout)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            let error = error as NSError

            switch error.code {
            case -999:
                await logManager?.info("Scraping: Search cancelled")
            case -1001:
                await sendSourceError("\(sourceName): Data request timed out. Trying fallback URLs if present.")
            case -1009:
                await logManager?.info("\(sourceName): The connection is offline")
            default:
                await sendSourceError("\(sourceName): Error in fetching website data \(error)")
            }

            return nil
        }
    }

    public func scrapeJson(source: Source, jsonData: Data) async -> SearchRequestResult? {
        guard let jsonParser = source.jsonParser else {
            return nil
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
                await sendSourceError("\(source.name): JSON parsing, couldn't fetch results: \(error)")
                await cleanApiCreds(api: api, sourceName: source.name)
            }
        }

        // If there are no results and the client secret isn't dynamic, just clear out the token
        if let api = source.api, jsonResults.isEmpty {
            await sendSourceError("\(source.name): JSON results were empty")
            await cleanApiCreds(api: api, sourceName: source.name)
        }

        var tempResults: [SearchResult] = []
        var magnets: [Magnet] = []

        // Iterate through results and grab what we can
        for result in jsonResults {
            var subResults: [JSON] = []

            let searchResult = parseJsonResult(result, jsonParser: jsonParser, source: source)

            // If subresults exist, iterate through those as well with the existing result
            // Otherwise append the applied result if it exists
            // Better to be redundant with checks rather than another for loop or filter
            if let subResultsQuery = jsonParser.subResults {
                // TODO: Add a for loop with subResultsQueries for further drilling into JSON
                subResults = result[subResultsQuery.components(separatedBy: ".")].arrayValue

                for subResult in subResults {
                    if let newSearchResult =
                        parseJsonResult(
                            subResult,
                            jsonParser: jsonParser,
                            source: source,
                            existingSearchResult: searchResult
                        ),
                        let magnetLink = newSearchResult.magnet.link,
                        magnetLink.starts(with: "magnet:"),
                        !tempResults.contains(newSearchResult)
                    {
                        tempResults.append(newSearchResult)
                        magnets.append(newSearchResult.magnet)
                    }
                }
            } else if
                let searchResult,
                let magnetLink = searchResult.magnet.link,
                magnetLink.starts(with: "magnet:"),
                !tempResults.contains(searchResult)
            {
                tempResults.append(searchResult)
                magnets.append(searchResult.magnet)
            }
        }

        return SearchRequestResult(results: tempResults, magnets: magnets)
    }

    // TODO: Add regex parsing for API
    public func parseJsonResult(_ result: JSON,
                                jsonParser: SourceJsonParser,
                                source: Source,
                                existingSearchResult: SearchResult? = nil) -> SearchResult?
    {
        // Enforce these parsers
        guard let titleParser = jsonParser.title else {
            return nil
        }

        var title: String? = existingSearchResult?.title
        if let existingTitle = title,
           let discriminatorQuery = titleParser.discriminator
        {
            let rawDiscriminator = result[discriminatorQuery.components(separatedBy: ".")].rawValue

            if !(rawDiscriminator is NSNull) {
                title = String(describing: rawDiscriminator) + existingTitle
            }
        } else if title == nil {
            let rawTitle = result[titleParser.query].rawValue
            title = rawTitle is NSNull ? nil : String(describing: rawTitle)
        }

        // Return if a title doesn't exist
        if title == nil && (jsonParser.subResults == nil && existingSearchResult == nil) {
            return nil
        }

        var magnetHash: String? = existingSearchResult?.magnet.hash
        if let magnetHashParser = jsonParser.magnetHash {
            let rawHash = result[magnetHashParser.query.components(separatedBy: ".")].rawValue

            if !(rawHash is NSNull) {
                magnetHash = String(describing: rawHash)
            }
        }

        var link: String? = existingSearchResult?.magnet.link
        if let magnetLinkParser = jsonParser.magnetLink, link == nil {
            let rawLink = result[magnetLinkParser.query.components(separatedBy: ".")].rawValue
            link = rawLink is NSNull ? nil : String(describing: rawLink)
        }

        // Return if a magnet hash doesn't exist
        let magnet = Magnet(hash: magnetHash, link: link, title: title, trackers: source.trackers)
        if magnet.hash == nil && (jsonParser.subResults == nil && existingSearchResult == nil) {
            return nil
        }

        var subName: String?
        if let subNameParser = jsonParser.subName {
            let rawSubName = result[subNameParser.query.components(separatedBy: ".")].rawValue
            subName = rawSubName is NSNull ? nil : String(describing: rawSubName)
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
            source: subName.map { "\(source.name) - \($0)" } ?? source.name,
            size: size,
            magnet: magnet,
            seeders: seeders,
            leechers: leechers
        )

        return result
    }

    // RSS feed scraper
    public func scrapeRss(source: Source, rss: String) async -> SearchRequestResult? {
        guard let rssParser = source.rssParser else {
            return nil
        }

        var items = Elements()

        do {
            let document = try SwiftSoup.parse(rss, "", Parser.xmlParser())
            items = try document.getElementsByTag(rssParser.items)
        } catch {
            await sendSourceError("\(source.name): RSS scraping error, couldn't fetch items: \(error)")

            return nil
        }

        var tempResults: [SearchResult] = []
        var magnets: [Magnet] = []

        for item in items {
            // Enforce these parsers
            guard let titleParser = rssParser.title else {
                continue
            }

            guard let title = try? runRssComplexQuery(
                item: item,
                query: titleParser.query,
                attribute: titleParser.attribute,
                discriminator: titleParser.discriminator,
                regexString: titleParser.regex
            ) else {
                continue
            }

            // Parse magnet link or translate hash
            var magnetHash: String?
            if let magnetHashParser = rssParser.magnetHash {
                magnetHash = try? runRssComplexQuery(
                    item: item,
                    query: magnetHashParser.query,
                    attribute: magnetHashParser.attribute,
                    discriminator: magnetHashParser.discriminator,
                    regexString: magnetHashParser.regex
                )
            }

            var href: String?
            if let magnetLinkParser = rssParser.magnetLink {
                href = try? runRssComplexQuery(
                    item: item,
                    query: magnetLinkParser.query,
                    attribute: magnetLinkParser.attribute,
                    discriminator: magnetLinkParser.discriminator,
                    regexString: magnetLinkParser.regex
                )
            }

            // Fetches the subName for the source if there is one
            var subName: String?
            if let subNameParser = rssParser.subName {
                subName = try? runRssComplexQuery(
                    item: item,
                    query: subNameParser.query,
                    attribute: subNameParser.attribute,
                    discriminator: subNameParser.discriminator,
                    regexString: subNameParser.regex
                )
            }

            // Continue if the magnet isn't valid
            // TODO: Possibly append magnet to a separate magnet array for debrid IA check
            let magnet = Magnet(hash: magnetHash, link: href, title: title, trackers: source.trackers)
            if magnet.hash == nil {
                continue
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
                title: title,
                source: subName.map { "\(source.name) - \($0)" } ?? source.name,
                size: size ?? "",
                magnet: magnet,
                seeders: seeders,
                leechers: leechers
            )

            if !tempResults.contains(result) {
                tempResults.append(result)
                magnets.append(result.magnet)
            }
        }

        return SearchRequestResult(results: tempResults, magnets: magnets)
    }

    // Complex query parsing for RSS scraping
    func runRssComplexQuery(item: Element,
                            query: String,
                            attribute: String,
                            discriminator: String?,
                            regexString: String?) throws -> String?
    {
        var parsedValue: String?

        switch attribute {
        case "text":
            parsedValue = try item.getElementsByTag(query).first()?.text()
        default:
            // If there's a key/value to lookup the attribute with, query it. Othewise assume the value is in the same attribute
            if let discriminator {
                let containerElement = try item.getElementsByAttributeValue(discriminator, query).first()
                parsedValue = try containerElement?.attr(attribute)
            } else {
                let containerElement = try item.getElementsByAttribute(attribute).first()
                parsedValue = try containerElement?.attr(attribute)
            }
        }

        // A capture group must be used in the provided regex
        if let regexString,
           let parsedValue
        {
            return runRegex(parsedValue: parsedValue, regexString: regexString)
        } else {
            return parsedValue
        }
    }

    // HTML scraper
    public func scrapeHtml(source: Source, website: String, html: String) async -> SearchRequestResult? {
        guard let htmlParser = source.htmlParser else {
            return nil
        }

        var rows = Elements()

        do {
            let document = try SwiftSoup.parse(html)
            rows = try document.select(htmlParser.rows)
        } catch {
            await sendSourceError("\(source.name): couldn't fetch rows: \(error)")

            return nil
        }

        var tempResults: [SearchResult] = []
        var magnets: [Magnet] = []

        // If there's an error, continue instead of returning with nothing
        for row in rows {
            do {
                // Enforce these parsers
                guard
                    let magnetParser = htmlParser.magnetLink,
                    let titleParser = htmlParser.title
                else {
                    continue
                }

                // Fetches the episode/movie title
                // Place here for filtering purposes
                guard let title = try? runHtmlComplexQuery(
                    row: row,
                    query: titleParser.query,
                    attribute: titleParser.attribute,
                    regexString: titleParser.regex
                ) else {
                    continue
                }

                // Fetches the magnet link
                // If the magnet is located on an external page, fetch the external page and grab the magnet link
                // External page fetching affects source performance
                var href: String
                if let externalMagnetQuery = magnetParser.externalLinkQuery, !externalMagnetQuery.isEmpty {
                    guard let externalMagnetUrl = try row.select(externalMagnetQuery).first()?.attr("href") else {
                        continue
                    }

                    let replacedMagnetUrl = externalMagnetUrl.starts(with: "/") ? website + externalMagnetUrl : externalMagnetUrl
                    guard
                        let data = await fetchWebsiteData(urlString: replacedMagnetUrl, sourceName: source.name),
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

                // Continue if the magnet isn't valid
                let magnet = Magnet(hash: nil, link: href)
                if magnet.hash == nil {
                    continue
                }

                var subName: String?
                if let subNameParser = htmlParser.subName {
                    subName = try? runHtmlComplexQuery(
                        row: row,
                        query: subNameParser.query,
                        attribute: subNameParser.attribute,
                        regexString: subNameParser.regex
                    )
                }

                // Fetches the size
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
                    title: title,
                    source: subName.map { "\(source.name) - \($0)" } ?? source.name,
                    size: size ?? "",
                    magnet: magnet,
                    seeders: seeders,
                    leechers: leechers
                )

                if !tempResults.contains(result) {
                    tempResults.append(result)
                    magnets.append(result.magnet)
                }
            } catch {
                await sendSourceError("\(source.name): \(error)")

                continue
            }
        }

        return SearchRequestResult(results: tempResults, magnets: magnets)
    }

    // Complex query parsing for HTML scraping
    func runHtmlComplexQuery(row: Element,
                             query: String,
                             attribute: String,
                             regexString: String?) throws -> String?
    {
        var parsedValue: String?

        let result = try row.select(query).first()

        switch attribute {
        case "text":
            parsedValue = try result?.text()
        default:
            parsedValue = try result?.attr(attribute)
        }

        if let parsedValue,
           let regexString
        {
            return runRegex(parsedValue: parsedValue, regexString: regexString)
        } else {
            return parsedValue
        }
    }

    func runRegex(parsedValue: String, regexString: String) -> String? {
        // TODO: Maybe dynamically parse flags
        let replacedRegexString = regexString
            .replacingOccurrences(of: "{query}", with: cleanedSearchText)

        guard
            let matchedRegex = try? Regex(
                replacedRegexString,
                options: [.caseInsensitive, .anchorsMatchLines]
            )
            .firstMatch(in: parsedValue)
        else {
            return nil
        }

        // Is there a capture group present? Otherwise return the original matched string
        if let group = matchedRegex.groups[safe: 0] {
            return group.value
        } else {
            return parsedValue
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

    func cleanApiCreds(api: SourceApi, sourceName: String) async {
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

        await sendSourceError("\(sourceName): \(responseArray.joined(separator: " "))")

        PersistenceController.shared.save(backgroundContext)
    }
}

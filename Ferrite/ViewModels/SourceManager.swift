//
//  SourceViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import CoreData
import Foundation
import UIKit

public class SourceManager: ObservableObject {
    var toastModel: ToastViewModel?

    @Published var availableSources: [SourceJson] = []

    @Published var urlErrorAlertText = ""
    @Published var showUrlErrorAlert = false

    @MainActor
    public func fetchSourcesFromUrl() async {
        let sourceListRequest = SourceList.fetchRequest()
        do {
            let sourceLists = try PersistenceController.shared.backgroundContext.fetch(sourceListRequest)
            var tempAvailableSources: [SourceJson] = []

            for sourceList in sourceLists {
                guard let url = URL(string: sourceList.urlString) else {
                    return
                }

                // Always get the up-to-date source list
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)

                let (data, _) = try await URLSession.shared.data(for: request)
                let sourceResponse = try JSONDecoder().decode(SourceListJson.self, from: data)

                for var source in sourceResponse.sources {
                    // If there is a minVersion, check and see if the source is valid
                    if checkAppVersion(minVersion: source.minVersion) {
                        source.author = sourceList.author
                        source.listId = sourceList.id

                        tempAvailableSources.append(source)
                    }
                }
            }

            availableSources = tempAvailableSources
        } catch {
            print(error)
        }
    }

    // Checks if the current app version is supported by the source
    func checkAppVersion(minVersion: String?) -> Bool {
        // If there's no min version, assume that every version is supported
        guard let minVersion = minVersion else {
            return true
        }

        var splitCurrentVersion = UIApplication.shared.appVersion
            .split(separator: ".")
            .map { Int($0) ?? 0 }

        if splitCurrentVersion.count < 3 {
            splitCurrentVersion += [Int](repeating: 0, count: 3 - splitCurrentVersion.count)
        }

        var splitMinVersion = minVersion
            .split(separator: ".")
            .map { Int($0) ?? 0 }

        if splitMinVersion.count < 3 {
            splitMinVersion += [Int](repeating: 0, count: 3 - splitMinVersion.count)
        }

        let combined = zip(splitCurrentVersion, splitMinVersion)
        return combined.allSatisfy({ part, minPart in
            part >= minPart
        })
    }

    // Fetches sources using the background context
    public func fetchInstalledSources() -> [Source] {
        let backgroundContext = PersistenceController.shared.backgroundContext

        if let sources = try? backgroundContext.fetch(Source.fetchRequest()) {
            return sources.compactMap { $0 }
        } else {
            return []
        }
    }

    public func installSource(sourceJson: SourceJson, doUpsert: Bool = false) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        // If there's no base URL and it isn't dynamic, return before any transactions occur
        let dynamicBaseUrl = sourceJson.dynamicBaseUrl ?? false

        if !dynamicBaseUrl, sourceJson.baseUrl == nil {
            Task { @MainActor in
                toastModel?.toastDescription = "Not adding this source because base URL parameters are malformed. Please contact the source dev."
            }

            print("Not adding this source because base URL parameters are malformed")
            return
        }

        // If a source exists, don't add the new one unless upserting
        let existingSourceRequest = Source.fetchRequest()
        existingSourceRequest.predicate = NSPredicate(format: "name == %@", sourceJson.name)
        existingSourceRequest.fetchLimit = 1

        if let existingSource = try? backgroundContext.fetch(existingSourceRequest).first {
            if doUpsert {
                PersistenceController.shared.delete(existingSource, context: backgroundContext)
            } else {
                Task { @MainActor in
                    toastModel?.toastDescription = "Could not install source with name \(sourceJson.name) because it is already installed."
                }
                return
            }
        }

        let newSource = Source(context: backgroundContext)
        newSource.id = UUID()
        newSource.name = sourceJson.name
        newSource.version = sourceJson.version
        newSource.dynamicBaseUrl = dynamicBaseUrl
        newSource.baseUrl = sourceJson.baseUrl
        newSource.fallbackUrls = dynamicBaseUrl ? nil : sourceJson.fallbackUrls
        newSource.author = sourceJson.author ?? "Unknown"
        newSource.listId = sourceJson.listId
        newSource.trackers = sourceJson.trackers

        if let sourceApiJson = sourceJson.api {
            addSourceApi(newSource: newSource, apiJson: sourceApiJson)
        }

        if let jsonParserJson = sourceJson.jsonParser {
            addJsonParser(newSource: newSource, jsonParserJson: jsonParserJson)
        }

        // Adds an RSS parser if present
        if let rssParserJson = sourceJson.rssParser {
            addRssParser(newSource: newSource, rssParserJson: rssParserJson)
        }

        // Adds an HTML parser if present
        if let htmlParserJson = sourceJson.htmlParser {
            addHtmlParser(newSource: newSource, htmlParserJson: htmlParserJson)
        }

        // Add an API condition as well
        if newSource.jsonParser != nil {
            newSource.preferredParser = Int16(SourcePreferredParser.siteApi.rawValue)
        } else if newSource.rssParser != nil {
            newSource.preferredParser = Int16(SourcePreferredParser.rss.rawValue)
        } else {
            newSource.preferredParser = Int16(SourcePreferredParser.scraping.rawValue)
        }

        newSource.enabled = true

        do {
            try backgroundContext.save()
        } catch {
            Task { @MainActor in
                toastModel?.toastDescription = error.localizedDescription
            }
        }
    }

    func addSourceApi(newSource: Source, apiJson: SourceApiJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        let newSourceApi = SourceApi(context: backgroundContext)
        newSourceApi.apiUrl = apiJson.apiUrl

        if let clientIdJson = apiJson.clientId {
            let newClientId = SourceApiClientId(context: backgroundContext)
            newClientId.query = clientIdJson.query
            newClientId.urlString = clientIdJson.url
            newClientId.dynamic = clientIdJson.dynamic ?? false
            newClientId.value = clientIdJson.value
            newClientId.responseType = clientIdJson.responseType?.rawValue ?? ApiCredentialResponseType.json.rawValue
            newClientId.expiryLength = clientIdJson.expiryLength ?? 0
            newClientId.timeStamp = Date()

            newSourceApi.clientId = newClientId
        }

        if let clientSecretJson = apiJson.clientSecret {
            let newClientSecret = SourceApiClientSecret(context: backgroundContext)
            newClientSecret.query = clientSecretJson.query
            newClientSecret.urlString = clientSecretJson.url
            newClientSecret.dynamic = clientSecretJson.dynamic ?? false
            newClientSecret.value = clientSecretJson.value
            newClientSecret.responseType = clientSecretJson.responseType?.rawValue ?? ApiCredentialResponseType.json.rawValue
            newClientSecret.expiryLength = clientSecretJson.expiryLength ?? 0
            newClientSecret.timeStamp = Date()

            newSourceApi.clientSecret = newClientSecret
        }

        newSource.api = newSourceApi
    }

    func addJsonParser(newSource: Source, jsonParserJson: SourceJsonParserJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        let newSourceJsonParser = SourceJsonParser(context: backgroundContext)
        newSourceJsonParser.searchUrl = jsonParserJson.searchUrl
        newSourceJsonParser.results = jsonParserJson.results
        newSourceJsonParser.subResults = jsonParserJson.subResults

        // Tune these complex queries to the final JSON parser format
        if let magnetLinkJson = jsonParserJson.magnetLink {
            let newSourceMagnetLink = SourceMagnetLink(context: backgroundContext)
            newSourceMagnetLink.query = magnetLinkJson.query
            newSourceMagnetLink.attribute = magnetLinkJson.attribute ?? "text"
            newSourceMagnetLink.discriminator = magnetLinkJson.discriminator

            newSourceJsonParser.magnetLink = newSourceMagnetLink
        }

        if let magnetHashJson = jsonParserJson.magnetHash {
            let newSourceMagnetHash = SourceMagnetHash(context: backgroundContext)
            newSourceMagnetHash.query = magnetHashJson.query
            newSourceMagnetHash.attribute = magnetHashJson.attribute ?? "text"
            newSourceMagnetHash.discriminator = magnetHashJson.discriminator

            newSourceJsonParser.magnetHash = newSourceMagnetHash
        }

        if let titleJson = jsonParserJson.title {
            let newSourceTitle = SourceTitle(context: backgroundContext)
            newSourceTitle.query = titleJson.query
            newSourceTitle.attribute = titleJson.attribute ?? "text"
            newSourceTitle.discriminator = titleJson.discriminator

            newSourceJsonParser.title = newSourceTitle
        }

        if let sizeJson = jsonParserJson.size {
            let newSourceSize = SourceSize(context: backgroundContext)
            newSourceSize.query = sizeJson.query
            newSourceSize.attribute = sizeJson.attribute ?? "text"
            newSourceSize.discriminator = sizeJson.discriminator

            newSourceJsonParser.size = newSourceSize
        }

        if let seedLeechJson = jsonParserJson.sl {
            let newSourceSeedLeech = SourceSeedLeech(context: backgroundContext)
            newSourceSeedLeech.seeders = seedLeechJson.seeders
            newSourceSeedLeech.leechers = seedLeechJson.leechers
            newSourceSeedLeech.combined = seedLeechJson.combined
            newSourceSeedLeech.attribute = seedLeechJson.attribute ?? "text"
            newSourceSeedLeech.discriminator = seedLeechJson.discriminator
            newSourceSeedLeech.seederRegex = seedLeechJson.seederRegex
            newSourceSeedLeech.leecherRegex = seedLeechJson.leecherRegex

            newSourceJsonParser.seedLeech = newSourceSeedLeech
        }

        newSource.jsonParser = newSourceJsonParser
    }

    func addRssParser(newSource: Source, rssParserJson: SourceRssParserJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        let newSourceRssParser = SourceRssParser(context: backgroundContext)
        newSourceRssParser.rssUrl = rssParserJson.rssUrl
        newSourceRssParser.searchUrl = rssParserJson.searchUrl
        newSourceRssParser.items = rssParserJson.items

        if let magnetLinkJson = rssParserJson.magnetLink {
            let newSourceMagnetLink = SourceMagnetLink(context: backgroundContext)
            newSourceMagnetLink.query = magnetLinkJson.query
            newSourceMagnetLink.attribute = magnetLinkJson.attribute ?? "text"
            newSourceMagnetLink.discriminator = magnetLinkJson.discriminator

            newSourceRssParser.magnetLink = newSourceMagnetLink
        }

        if let magnetHashJson = rssParserJson.magnetHash {
            let newSourceMagnetHash = SourceMagnetHash(context: backgroundContext)
            newSourceMagnetHash.query = magnetHashJson.query
            newSourceMagnetHash.attribute = magnetHashJson.attribute ?? "text"
            newSourceMagnetHash.discriminator = magnetHashJson.discriminator

            newSourceRssParser.magnetHash = newSourceMagnetHash
        }

        if let titleJson = rssParserJson.title {
            let newSourceTitle = SourceTitle(context: backgroundContext)
            newSourceTitle.query = titleJson.query
            newSourceTitle.attribute = titleJson.attribute ?? "text"
            newSourceTitle.discriminator = titleJson.discriminator

            newSourceRssParser.title = newSourceTitle
        }

        if let sizeJson = rssParserJson.size {
            let newSourceSize = SourceSize(context: backgroundContext)
            newSourceSize.query = sizeJson.query
            newSourceSize.attribute = sizeJson.attribute ?? "text"
            newSourceSize.discriminator = sizeJson.discriminator

            newSourceRssParser.size = newSourceSize
        }

        if let seedLeechJson = rssParserJson.sl {
            let newSourceSeedLeech = SourceSeedLeech(context: backgroundContext)
            newSourceSeedLeech.seeders = seedLeechJson.seeders
            newSourceSeedLeech.leechers = seedLeechJson.leechers
            newSourceSeedLeech.combined = seedLeechJson.combined
            newSourceSeedLeech.attribute = seedLeechJson.attribute ?? "text"
            newSourceSeedLeech.discriminator = seedLeechJson.discriminator
            newSourceSeedLeech.seederRegex = seedLeechJson.seederRegex
            newSourceSeedLeech.leecherRegex = seedLeechJson.leecherRegex

            newSourceRssParser.seedLeech = newSourceSeedLeech
        }

        newSource.rssParser = newSourceRssParser
    }

    func addHtmlParser(newSource: Source, htmlParserJson: SourceHtmlParserJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        let newSourceHtmlParser = SourceHtmlParser(context: backgroundContext)
        newSourceHtmlParser.searchUrl = htmlParserJson.searchUrl
        newSourceHtmlParser.rows = htmlParserJson.rows

        // Adds a title complex query if present
        if let titleJson = htmlParserJson.title {
            let newSourceTitle = SourceTitle(context: backgroundContext)
            newSourceTitle.query = titleJson.query
            newSourceTitle.attribute = titleJson.attribute ?? "text"
            newSourceTitle.regex = titleJson.regex

            newSourceHtmlParser.title = newSourceTitle
        }

        // Adds a size complex query if present
        if let sizeJson = htmlParserJson.size {
            let newSourceSize = SourceSize(context: backgroundContext)
            newSourceSize.query = sizeJson.query
            newSourceSize.attribute = sizeJson.attribute ?? "text"
            newSourceSize.regex = sizeJson.regex

            newSourceHtmlParser.size = newSourceSize
        }

        if let seedLeechJson = htmlParserJson.sl {
            let newSourceSeedLeech = SourceSeedLeech(context: backgroundContext)
            newSourceSeedLeech.seeders = seedLeechJson.seeders
            newSourceSeedLeech.leechers = seedLeechJson.leechers
            newSourceSeedLeech.combined = seedLeechJson.combined
            newSourceSeedLeech.attribute = seedLeechJson.attribute ?? "text"
            newSourceSeedLeech.seederRegex = seedLeechJson.seederRegex
            newSourceSeedLeech.leecherRegex = seedLeechJson.leecherRegex

            newSourceHtmlParser.seedLeech = newSourceSeedLeech
        }

        // Adds a magnet complex query and its unique properties
        let newSourceMagnet = SourceMagnetLink(context: backgroundContext)
        newSourceMagnet.externalLinkQuery = htmlParserJson.magnet.externalLinkQuery
        newSourceMagnet.query = htmlParserJson.magnet.query
        newSourceMagnet.attribute = htmlParserJson.magnet.attribute
        newSourceMagnet.regex = htmlParserJson.magnet.regex

        newSourceHtmlParser.magnetLink = newSourceMagnet

        newSource.htmlParser = newSourceHtmlParser
    }

    @MainActor
    public func addSourceList(sourceUrl: String, existingSourceList: SourceList?) async -> Bool {
        let backgroundContext = PersistenceController.shared.backgroundContext

        if sourceUrl.isEmpty || URL(string: sourceUrl) == nil {
            urlErrorAlertText = "The provided source list is invalid. Please check if the URL is formatted properly."
            showUrlErrorAlert.toggle()

            return false
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: URL(string: sourceUrl)!))
            let rawResponse = try JSONDecoder().decode(SourceListJson.self, from: data)

            if let existingSourceList = existingSourceList {
                existingSourceList.urlString = sourceUrl
                existingSourceList.name = rawResponse.name
                existingSourceList.author = rawResponse.author

                try PersistenceController.shared.container.viewContext.save()
            } else {
                let sourceListRequest = SourceList.fetchRequest()
                let urlPredicate = NSPredicate(format: "urlString == %@", sourceUrl)
                let infoPredicate = NSPredicate(format: "author == %@ AND name == %@", rawResponse.author, rawResponse.name)
                sourceListRequest.predicate = NSCompoundPredicate(type: .or, subpredicates: [urlPredicate, infoPredicate])
                sourceListRequest.fetchLimit = 1

                if (try? backgroundContext.fetch(sourceListRequest).first) != nil {
                    urlErrorAlertText = "An existing source with this information was found. Please try editing the source list instead."
                    showUrlErrorAlert.toggle()

                    return false
                }

                let newSourceUrl = SourceList(context: backgroundContext)
                newSourceUrl.id = UUID()
                newSourceUrl.urlString = sourceUrl
                newSourceUrl.name = rawResponse.name
                newSourceUrl.author = rawResponse.author

                try backgroundContext.save()
            }

            return true
        } catch {
            print(error)
            urlErrorAlertText = error.localizedDescription
            showUrlErrorAlert.toggle()

            return false
        }
    }
}

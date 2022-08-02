//
//  SourceViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import CoreData
import Foundation

public class SourceManager: ObservableObject {
    var toastModel: ToastViewModel?

    @Published var availableSources: [SourceJson] = []

    @Published var urlErrorAlertText = ""
    @Published var showUrlErrorAlert = false

    @MainActor
    public func fetchSourcesFromUrl() async {
        let sourceUrlRequest = SourceList.fetchRequest()
        do {
            let sourceUrls = try PersistenceController.shared.backgroundContext.fetch(sourceUrlRequest)
            var tempSourceUrls: [SourceJson] = []

            for sourceUrl in sourceUrls {
                guard let url = URL(string: sourceUrl.urlString) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
                let sourceResponse = try JSONDecoder().decode(SourceListJson.self, from: data)

                tempSourceUrls += sourceResponse.sources
            }

            availableSources = tempSourceUrls
        } catch {
            print(error)
        }
    }

    public func installSource(sourceJson: SourceJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        // If a source exists, don't add the new one
        let existingSourceRequest = Source.fetchRequest()
        existingSourceRequest.predicate = NSPredicate(format: "name == %@", sourceJson.name)
        existingSourceRequest.fetchLimit = 1

        let existingSource = try? backgroundContext.fetch(existingSourceRequest).first
        if existingSource != nil {
            Task { @MainActor in
                toastModel?.toastDescription = "Could not install source with name \(sourceJson.name) because it is already installed."
            }

            return
        }

        let newSource = Source(context: backgroundContext)
        newSource.name = sourceJson.name
        newSource.version = sourceJson.version
        newSource.baseUrl = sourceJson.baseUrl

        // Adds an HTML parser if present
        if let htmlParserJson = sourceJson.htmlParser {
            let newSourceHtmlParser = SourceHtmlParser(context: backgroundContext)
            newSourceHtmlParser.searchUrl = htmlParserJson.searchUrl
            newSourceHtmlParser.rows = htmlParserJson.rows

            // Adds a title complex query if present
            if let titleJson = htmlParserJson.title {
                let newSourceTitle = SourceTitle(context: backgroundContext)
                newSourceTitle.query = titleJson.query
                newSourceTitle.attribute = titleJson.attribute
                newSourceTitle.regex = titleJson.regex

                newSourceHtmlParser.title = newSourceTitle
            }

            // Adds a size complex query if present
            if let sizeJson = htmlParserJson.size {
                let newSourceSize = SourceSize(context: backgroundContext)
                newSourceSize.query = sizeJson.query
                newSourceSize.attribute = sizeJson.attribute
                newSourceSize.regex = sizeJson.regex

                newSourceHtmlParser.size = newSourceSize
            }

            if let seedLeechJson = htmlParserJson.sl {
                let newSourceSeedLeech = SourceSeedLeech(context: backgroundContext)
                newSourceSeedLeech.seeders = seedLeechJson.seeders
                newSourceSeedLeech.leechers = seedLeechJson.leechers
                newSourceSeedLeech.combined = seedLeechJson.combined
                newSourceSeedLeech.attribute = seedLeechJson.attribute
                newSourceSeedLeech.seederRegex = seedLeechJson.seederRegex
                newSourceSeedLeech.leecherRegex = seedLeechJson.leecherRegex

                newSourceHtmlParser.seedLeech = newSourceSeedLeech
            }

            // Adds a magnet complex query and its unique properties
            let newSourceMagnet = SourceMagnet(context: backgroundContext)
            newSourceMagnet.externalLinkQuery = htmlParserJson.magnet.externalLinkQuery
            newSourceMagnet.query = htmlParserJson.magnet.query
            newSourceMagnet.attribute = htmlParserJson.magnet.attribute
            newSourceMagnet.regex = htmlParserJson.magnet.regex

            newSourceHtmlParser.magnet = newSourceMagnet

            newSource.htmlParser = newSourceHtmlParser
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

    @MainActor
    public func addSourceList(sourceUrl: String) async -> Bool {
        let backgroundContext = PersistenceController.shared.backgroundContext

        if sourceUrl.isEmpty || URL(string: sourceUrl) == nil {
            urlErrorAlertText = "The provided source list is invalid. Please check if the URL is formatted properly."
            showUrlErrorAlert.toggle()

            return false
        }

        let sourceUrlRequest = SourceList.fetchRequest()
        sourceUrlRequest.predicate = NSPredicate(format: "urlString == %@", sourceUrl)
        sourceUrlRequest.fetchLimit = 1

        if let existingSourceUrl = try? backgroundContext.fetch(sourceUrlRequest).first {
            print("Existing source URL found")
            PersistenceController.shared.delete(existingSourceUrl, context: backgroundContext)
        }

        let newSourceUrl = SourceList(context: backgroundContext)
        newSourceUrl.urlString = sourceUrl

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: URL(string: sourceUrl)!))
            if let rawResponse = try? JSONDecoder().decode(SourceListJson.self, from: data) {
                newSourceUrl.repoName = rawResponse.repoName
            }

            try backgroundContext.save()

            return true
        } catch {
            urlErrorAlertText = error.localizedDescription
            showUrlErrorAlert.toggle()

            return false
        }
    }
}

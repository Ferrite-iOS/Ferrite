//
//  SourceManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import Foundation
import SwiftUI

public class PluginManager: ObservableObject {
    var toastModel: ToastViewModel?

    @Published var availableSources: [SourceJson] = []
    @Published var availableActions: [ActionJson] = []

    @Published var showBrokenDefaultActionAlert = false

    @MainActor
    public func fetchPluginsFromUrl() async {
        let pluginListRequest = PluginList.fetchRequest()
        do {
            let pluginLists = try PersistenceController.shared.backgroundContext.fetch(pluginListRequest)

            // Clean availablePlugin arrays for repopulation
            availableSources = []
            availableActions = []

            for pluginList in pluginLists {
                guard let url = URL(string: pluginList.urlString) else {
                    return
                }

                // Always get the up-to-date source list
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)

                let (data, _) = try await URLSession.shared.data(for: request)
                let pluginResponse = try JSONDecoder().decode(PluginListJson.self, from: data)

                if let sources = pluginResponse.sources {
                    // Faster and more performant to map instead of a for loop
                    availableSources += sources.compactMap { inputJson in
                        if checkAppVersion(minVersion: inputJson.minVersion) {
                            return SourceJson(
                                name: inputJson.name,
                                version: inputJson.version,
                                minVersion: inputJson.minVersion,
                                baseUrl: inputJson.baseUrl,
                                fallbackUrls: inputJson.fallbackUrls,
                                dynamicBaseUrl: inputJson.dynamicBaseUrl,
                                trackers: inputJson.trackers,
                                api: inputJson.api,
                                jsonParser: inputJson.jsonParser,
                                rssParser: inputJson.rssParser,
                                htmlParser: inputJson.htmlParser,
                                author: pluginList.author,
                                listId: pluginList.id,
                                tags: inputJson.tags
                            )
                        } else {
                            return nil
                        }
                    }
                }

                if let actions = pluginResponse.actions {
                    availableActions += actions.compactMap { inputJson in
                        if checkAppVersion(minVersion: inputJson.minVersion) {
                            return ActionJson(
                                name: inputJson.name,
                                version: inputJson.version,
                                minVersion: inputJson.minVersion,
                                requires: inputJson.requires,
                                deeplink: inputJson.deeplink,
                                author: pluginList.author,
                                listId: pluginList.id,
                                tags: inputJson.tags
                            )
                        } else {
                            return nil
                        }
                    }
                }
            }
        } catch {
            let error = error as NSError
            if error.code != -999 {
                toastModel?.updateToastDescription("Plugin fetch error: \(error)")
            }

            print("Plugin fetch error: \(error)")
        }    
    }

    // Check if underlying type is Source or Action
    func fetchFilteredPlugins<P: Plugin, PJ: PluginJson>(installedPlugins: FetchedResults<P>, searchText: String) -> [PJ] {
        let availablePlugins: [PJ] = fetchCastedPlugins(PJ.self)

        return availablePlugins
            .filter { availablePlugin in
                let pluginExists = installedPlugins.contains(where: {
                    availablePlugin.name == $0.name &&
                    availablePlugin.listId == $0.listId &&
                    availablePlugin.author == $0.author
                })

                if searchText.isEmpty {
                    return !pluginExists
                } else {
                    return !pluginExists && availablePlugin.name.lowercased().contains(searchText.lowercased())
                }
            }
    }

    func fetchUpdatedPlugins<P: Plugin, PJ: PluginJson>(installedPlugins: FetchedResults<P>, searchText: String) -> [PJ] {
        var updatedPlugins: [PJ] = []
        let availablePlugins: [PJ] = fetchCastedPlugins(PJ.self)

        for plugin in installedPlugins {
            if let availablePlugin = availablePlugins.first(where: {
                plugin.listId == $0.listId && plugin.name == $0.name && plugin.author == $0.author
            }),
                availablePlugin.version > plugin.version
            {
                updatedPlugins.append(availablePlugin)
            }
        }

        return updatedPlugins
            .filter {
                searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
            }
    }

    func fetchCastedPlugins<PJ: PluginJson>(_ forType: PJ.Type) -> [PJ] {
        switch String(describing: PJ.self) {
        case "SourceJson":
            return availableSources as? [PJ] ?? []
        case "ActionJson":
            return availableActions as? [PJ] ?? []
        default:
            return []
        }
    }

    // Checks if the current app version is supported by the source
    func checkAppVersion(minVersion: String?) -> Bool {
        // If there's no min version, assume that every version is supported
        guard let minVersion else {
            return true
        }

        return Application.shared.appVersion >= minVersion
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

    @MainActor
    public func runDebridAction(urlString: String?, currentChoiceSheet: inout NavigationViewModel.ChoiceSheetType?) {
        let context = PersistenceController.shared.backgroundContext

        if
            let defaultDebridActionName = UserDefaults.standard.string(forKey: "Actions.DefaultDebridName"),
            let defaultDebridActionList = UserDefaults.standard.string(forKey: "Actions.DefaultDebridList")
        {
            let actionFetchRequest = Action.fetchRequest()
            actionFetchRequest.fetchLimit = 1
            actionFetchRequest.predicate = NSPredicate(format: "name == %@ AND listId == %@", defaultDebridActionName, defaultDebridActionList)

            if let fetchedAction = try? context.fetch(actionFetchRequest).first {
                runDeeplinkAction(fetchedAction, urlString: urlString)
            } else {
                currentChoiceSheet = .action
                UserDefaults.standard.set(nil, forKey: "Actions.DefaultDebridName")
                UserDefaults.standard.set(nil, forKey: "Action.DefaultDebridList")

                showBrokenDefaultActionAlert.toggle()
            }
        } else {
            currentChoiceSheet = .action
        }
    }

    @MainActor
    public func runMagnetAction(urlString: String?, currentChoiceSheet: inout NavigationViewModel.ChoiceSheetType?) {
        let context = PersistenceController.shared.backgroundContext

        if
            let defaultMagnetActionName = UserDefaults.standard.string(forKey: "Actions.DefaultMagnetName"),
            let defaultMagnetActionList = UserDefaults.standard.string(forKey: "Actions.DefaultMagnetList")
        {
            let actionFetchRequest = Action.fetchRequest()
            actionFetchRequest.fetchLimit = 1
            actionFetchRequest.predicate = NSPredicate(format: "name == %@ AND listId == %@", defaultMagnetActionName, defaultMagnetActionList)

            if let fetchedAction = try? context.fetch(actionFetchRequest).first {
                runDeeplinkAction(fetchedAction, urlString: urlString)
            } else {
                currentChoiceSheet = .action
                UserDefaults.standard.set(nil, forKey: "Actions.DefaultMagnetName")
                UserDefaults.standard.set(nil, forKey: "Actions.DefaultMagnetList")

                showBrokenDefaultActionAlert.toggle()
            }
        } else {
            currentChoiceSheet = .action
        }
    }

    // The iOS version of Ferrite only runs deeplink actions
    @MainActor
    public func runDeeplinkAction(_ action: Action, urlString: String?) {
        guard let deeplink = action.deeplink, let urlString else {
            toastModel?.updateToastDescription("Could not run action: \(action.name) since there is no deeplink to execute. Contact the action dev!")
            print("Could not run action: \(action.name) since there is no deeplink to execute.")

            return
        }

        let playbackUrl = URL(string: deeplink.replacingOccurrences(of: "{link}", with: urlString))

        if let playbackUrl {
            UIApplication.shared.open(playbackUrl)
        } else {
            toastModel?.updateToastDescription("Could not run action: \(action.name) because the created deeplink was invalid. Contact the action dev!")
            print("Could not run action: \(action.name) because the created deeplink (\(String(describing: playbackUrl))) was invalid")
        }
    }

    public func installAction(actionJson: ActionJson?, doUpsert: Bool = false) async {
        guard let actionJson else {
            await toastModel?.updateToastDescription("Action addition error: No action present. Contact the app dev!")
            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext

        if actionJson.requires.count < 1 {
            await toastModel?.updateToastDescription("Action addition error: actions must require an input. Please contact the action dev!")
            print("Action name \(actionJson.name) does not have a requires parameter")
            
            return
        }

        guard let deeplink = actionJson.deeplink else {
            await toastModel?.updateToastDescription("Action addition error: only deeplink actions can be added to Ferrite iOS. Please contact the action dev!")
            print("Action name \(actionJson.name) did not have a deeplink")

            return
        }

        let existingActionRequest = Action.fetchRequest()
        existingActionRequest.predicate = NSPredicate(format: "name == %@", actionJson.name)
        existingActionRequest.fetchLimit = 1

        if let existingAction = try? backgroundContext.fetch(existingActionRequest).first {
            if doUpsert {
                PersistenceController.shared.delete(existingAction, context: backgroundContext)
            } else {
                await toastModel?.updateToastDescription("Could not install action with name \(actionJson.name) because it is already installed")
                print("Action name \(actionJson.name) already exists in user's DB")

                return
            }
        }

        let newAction = Action(context: backgroundContext)
        newAction.id = UUID()
        newAction.name = actionJson.name
        newAction.version = actionJson.version
        newAction.author = actionJson.author ?? "Unknown"
        newAction.listId = actionJson.listId
        newAction.requires = actionJson.requires.map { $0.rawValue }
        newAction.enabled = true

        if let jsonTags = actionJson.tags {
            for tag in jsonTags {
                let newTag = PluginTag(context: backgroundContext)
                newTag.name = tag.name
                newTag.colorHex = tag.colorHex

                newTag.parentAction = newAction
            }
        }

        newAction.deeplink = deeplink

        do {
            try backgroundContext.save()
        } catch {
            await toastModel?.updateToastDescription("Action addition error: \(error)")
            print("Action addition error: \(error)")
        }
    }

    public func installSource(sourceJson: SourceJson?, doUpsert: Bool = false) async {
        guard let sourceJson else {
            await toastModel?.updateToastDescription("Source addition error: No source present. Contact the app dev!")
            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext

        // If there's no base URL and it isn't dynamic, return before any transactions occur
        let dynamicBaseUrl = sourceJson.dynamicBaseUrl ?? false
        if !dynamicBaseUrl, sourceJson.baseUrl == nil {
            await toastModel?.updateToastDescription("Not adding this source because base URL parameters are malformed. Please contact the source dev.")
            print("Not adding source \(sourceJson.name) because base URL parameters are malformed")
    
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
                await toastModel?.updateToastDescription("Could not install source with name \(sourceJson.name) because it is already installed.")
                print("Source name \(sourceJson.name) already exists")

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

        if let jsonTags = sourceJson.tags {
            for tag in jsonTags {
                let newTag = PluginTag(context: backgroundContext)
                newTag.name = tag.name
                newTag.colorHex = tag.colorHex

                newTag.parentSource = newSource
            }
        }

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
            await toastModel?.updateToastDescription("Source addition error: \(error)")
            print("Source addition error: \(error)")
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

        if let subNameJson = jsonParserJson.subName {
            let newSourceSubName = SourceSubName(context: backgroundContext)
            newSourceSubName.query = subNameJson.query
            newSourceSubName.attribute = subNameJson.query
            newSourceSubName.discriminator = subNameJson.discriminator

            newSourceJsonParser.subName = newSourceSubName
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
            newSourceMagnetLink.regex = magnetLinkJson.regex

            newSourceRssParser.magnetLink = newSourceMagnetLink
        }

        if let magnetHashJson = rssParserJson.magnetHash {
            let newSourceMagnetHash = SourceMagnetHash(context: backgroundContext)
            newSourceMagnetHash.query = magnetHashJson.query
            newSourceMagnetHash.attribute = magnetHashJson.attribute ?? "text"
            newSourceMagnetHash.discriminator = magnetHashJson.discriminator
            newSourceMagnetHash.regex = magnetHashJson.regex

            newSourceRssParser.magnetHash = newSourceMagnetHash
        }

        if let subNameJson = rssParserJson.subName {
            let newSourceSubName = SourceSubName(context: backgroundContext)
            newSourceSubName.query = subNameJson.query
            newSourceSubName.attribute = subNameJson.attribute ?? "text"
            newSourceSubName.discriminator = subNameJson.discriminator
            newSourceSubName.regex = subNameJson.regex

            newSourceRssParser.subName = newSourceSubName
        }

        if let titleJson = rssParserJson.title {
            let newSourceTitle = SourceTitle(context: backgroundContext)
            newSourceTitle.query = titleJson.query
            newSourceTitle.attribute = titleJson.attribute ?? "text"
            newSourceTitle.discriminator = titleJson.discriminator
            newSourceTitle.regex = titleJson.regex

            newSourceRssParser.title = newSourceTitle
        }

        if let sizeJson = rssParserJson.size {
            let newSourceSize = SourceSize(context: backgroundContext)
            newSourceSize.query = sizeJson.query
            newSourceSize.attribute = sizeJson.attribute ?? "text"
            newSourceSize.discriminator = sizeJson.discriminator
            newSourceSize.regex = sizeJson.regex

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

        if let subNameJson = htmlParserJson.subName {
            let newSourceSubName = SourceSubName(context: backgroundContext)
            newSourceSubName.query = subNameJson.query
            newSourceSubName.attribute = subNameJson.attribute ?? "text"
            newSourceSubName.regex = subNameJson.regex

            newSourceHtmlParser.subName = newSourceSubName
        }

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

    // Adds a plugin list
    // Can move this to PersistenceController if needed
    public func addPluginList(_ url: String, isSheet: Bool = false, existingPluginList: PluginList? = nil) async throws {
        let backgroundContext = PersistenceController.shared.backgroundContext

        if url.isEmpty || URL(string: url) == nil {
            throw PluginManagerError.ListAddition(description: "The provided source list is invalid. Please check if the URL is formatted properly.")
        }

        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: URL(string: url)!))
        let rawResponse = try JSONDecoder().decode(PluginListJson.self, from: data)

        if let existingPluginList {
            existingPluginList.urlString = url
            existingPluginList.name = rawResponse.name
            existingPluginList.author = rawResponse.author

            try PersistenceController.shared.container.viewContext.save()
        } else {
            let pluginListRequest = PluginList.fetchRequest()
            let urlPredicate = NSPredicate(format: "urlString == %@", url)
            let infoPredicate = NSPredicate(format: "author == %@ AND name == %@", rawResponse.author, rawResponse.name)
            pluginListRequest.predicate = NSCompoundPredicate(type: .or, subpredicates: [urlPredicate, infoPredicate])
            pluginListRequest.fetchLimit = 1

            if let existingPluginList = try? backgroundContext.fetch(pluginListRequest).first, !isSheet {
                PersistenceController.shared.delete(existingPluginList, context: backgroundContext)
            } else if isSheet {
                throw PluginManagerError.ListAddition(description: "An existing plugin list with this information was found. Please try editing an existing plugin list instead.")
            }

            let newPluginList = PluginList(context: backgroundContext)
            newPluginList.id = UUID()
            newPluginList.urlString = url
            newPluginList.name = rawResponse.name
            newPluginList.author = rawResponse.author

            try backgroundContext.save()
        }
    }
}

//
//  SourceManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import Foundation
import SwiftUI

public class PluginManager: ObservableObject {
    var logManager: LoggingManager?
    let kodi: Kodi = .init()

    @Published var availableSources: [SourceJson] = []
    @Published var availableActions: [ActionJson] = []

    @Published var showActionErrorAlert = false
    @Published var actionErrorAlertMessage: String = ""

    @Published var showActionSuccessAlert = false
    @Published var actionSuccessAlertMessage: String = ""

    @MainActor
    func cleanAvailablePlugins() {
        availableSources = []
        availableActions = []
    }

    @MainActor
    func updateAvailablePlugins(_ newPlugins: AvailablePlugins) {
        availableSources += newPlugins.availableSources
        availableActions += newPlugins.availableActions
    }

    public func fetchPluginsFromUrl() async {
        let pluginListRequest = PluginList.fetchRequest()
        guard let pluginLists = try? PersistenceController.shared.backgroundContext.fetch(pluginListRequest) else {
            await logManager?.error("PluginManager: No plugin lists found")
            return
        }

        // Clean availablePlugin arrays for repopulation
        await cleanAvailablePlugins()

        await logManager?.info("Starting fetch of plugin lists")

        await withTaskGroup(of: (AvailablePlugins?, String).self) { group in
            for pluginList in pluginLists {
                guard let url = URL(string: pluginList.urlString) else {
                    return
                }

                group.addTask {
                    var availablePlugins: AvailablePlugins?

                    do {
                        availablePlugins = try await self.fetchPluginList(pluginList: pluginList, url: url)
                    } catch {
                        let error = error as NSError

                        switch error.code {
                        case -999:
                            await self.logManager?.info("PluginManager: \(pluginList.name): List fetch cancelled")
                        case -1009:
                            await self.logManager?.info("PluginManager: \(pluginList.name): The connection is offline")
                        default:
                            await self.logManager?.error("Plugin fetch: \(pluginList.name): \(error)", showToast: false)
                        }
                    }

                    return (availablePlugins, pluginList.name)
                }
            }

            var failedLists: [String] = []
            for await (availablePlugins, pluginListName) in group {
                if let availablePlugins {
                    await updateAvailablePlugins(availablePlugins)
                } else {
                    failedLists.append(pluginListName)
                }
            }

            if !failedLists.isEmpty {
                let joinedLists = failedLists.joined(separator: ", ")
                await logManager?.info(
                    "Plugins: Errors in plugin lists \(joinedLists). See above.",
                    description: "There were errors in plugin lists \(joinedLists). Check the logs for more details."
                )
            }
        }

        await logManager?.info("Plugin list fetch finished")
    }

    func fetchPluginList(pluginList: PluginList, url: URL) async throws -> AvailablePlugins? {
        var tempSources: [SourceJson] = []
        var tempActions: [ActionJson] = []

        // Always get the up-to-date source list
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)

        let (data, _) = try await URLSession.shared.data(for: request)
        let pluginResponse = try JSONDecoder().decode(PluginListJson.self, from: data)

        if let sources = pluginResponse.sources {
            // Faster and more performant to map instead of a for loop
            tempSources += sources.compactMap { inputJson in
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
                        listName: pluginList.name,
                        tags: inputJson.tags
                    )
                } else {
                    return nil
                }
            }
        }

        if let actions = pluginResponse.actions {
            tempActions += actions.compactMap { inputJson in
                if
                    let deeplink = inputJson.deeplink,
                    checkAppVersion(minVersion: inputJson.minVersion),
                    let filteredDeeplinks = getFilteredDeeplinks(deeplink)
                {
                    return ActionJson(
                        name: inputJson.name,
                        version: inputJson.version,
                        minVersion: inputJson.minVersion,
                        requires: inputJson.requires,
                        deeplink: filteredDeeplinks,
                        author: pluginList.author,
                        listId: pluginList.id,
                        listName: pluginList.name,
                        tags: inputJson.tags
                    )
                } else {
                    return nil
                }
            }
        }

        return AvailablePlugins(availableSources: tempSources, availableActions: tempActions)
    }

    // Checks if a deeplink action is present and if there's a single action for the OS (or fallback)
    func getFilteredDeeplinks(_ deeplinks: [DeeplinkActionJson]) -> [DeeplinkActionJson]? {
        let osArray = deeplinks.filter { deeplink in
            deeplink.os.contains(where: { $0.lowercased() == Application.shared.os.lowercased() })
        }

        if osArray.count == 1 {
            return osArray
        } else {
            let universalArray = deeplinks.filter { deeplink in
                deeplink.os.isEmpty
            }

            if universalArray.count == 1 {
                return universalArray
            } else {
                return nil
            }
        }
    }

    // forType required to guide generic inferences
    func fetchFilteredPlugins<PJ: PluginJson>(forType: PJ.Type,
                                              installedPlugins: FetchedResults<some Plugin>,
                                              searchText: String) -> [PJ]
    {
        let availablePlugins: [PJ] = fetchCastedPlugins(forType)

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

    func fetchUpdatedPlugins<PJ: PluginJson>(forType: PJ.Type,
                                             installedPlugins: FetchedResults<some Plugin>,
                                             searchText: String) -> [PJ]
    {
        var updatedPlugins: [PJ] = []
        let availablePlugins: [PJ] = fetchCastedPlugins(forType)

        for plugin in installedPlugins {
            if let availablePlugin = availablePlugins.first(where: {
                plugin.listId == $0.listId &&
                    plugin.name == $0.name &&
                    plugin.author == $0.author
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
    public func runDefaultAction(urlString: String?, navModel: NavigationViewModel) {
        let context = PersistenceController.shared.backgroundContext

        guard let urlString else {
            logManager?.error("Default action: Could not run because the URL is invalid")
            return
        }

        let defaultsKey: String
        // Assume this is a magnet link
        if urlString.starts(with: "magnet") {
            defaultsKey = "Actions.DefaultMagnet"
        } else {
            defaultsKey = "Actions.DefaultDebrid"
        }

        if
            let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
            let defaultAction = CodableWrapper<DefaultAction>(rawValue: rawValue)?.value
        {
            switch defaultAction {
            case .none:
                navModel.currentChoiceSheet = .action
            case .share:
                navModel.activityItems = [urlString]
                navModel.currentChoiceSheet = .activity
            case .kodi:
                navModel.kodiExpanded = true
                navModel.currentChoiceSheet = .action
            case let .custom(name, listId):
                let actionFetchRequest = Action.fetchRequest()
                actionFetchRequest.fetchLimit = 1
                actionFetchRequest.predicate = NSPredicate(format: "name == %@ AND listId == %@", name, listId)

                if let fetchedAction = try? context.fetch(actionFetchRequest).first {
                    runDeeplinkAction(fetchedAction, urlString: urlString)
                } else {
                    navModel.currentChoiceSheet = .action
                    UserDefaults.standard.set(CodableWrapper<DefaultAction>(value: .none).rawValue, forKey: "Actions.DefaultDebrid")

                    actionErrorAlertMessage =
                        "The default action could not be run. The action choice sheet has been opened. \n\n" +
                        "Please check your default actions in Settings"
                    showActionErrorAlert.toggle()
                }
            }
        } else {
            navModel.currentChoiceSheet = .action
        }
    }

    // The iOS version of Ferrite only runs deeplink actions
    @MainActor
    public func runDeeplinkAction(_ action: Action, urlString: String?) {
        guard let deeplink = action.deeplink, let urlString else {
            actionErrorAlertMessage = "Could not run action: \(action.name) since there is no deeplink to execute. Contact the action dev!"
            showActionErrorAlert.toggle()

            logManager?.error("Could not run action: \(action.name) since there is no deeplink to execute.")

            return
        }

        let playbackUrl = URL(string: deeplink.replacingOccurrences(of: "{link}", with: urlString))

        if let playbackUrl {
            UIApplication.shared.open(playbackUrl)
        } else {
            actionErrorAlertMessage = "Could not run action: \(action.name) because the created deeplink was invalid. Contact the action dev!"
            showActionErrorAlert.toggle()

            logManager?.error("Could not run action: \(action.name) because the created deeplink (\(String(describing: playbackUrl))) was invalid")
        }
    }

    @MainActor
    public func sendToKodi(urlString: String?, server: KodiServer) async {
        guard let urlString else {
            actionErrorAlertMessage = "Could not send URL to Kodi since there is no playback URL to send"
            showActionErrorAlert.toggle()

            logManager?.error("Kodi action: Could not send URL to Kodi since there is no playback URL to send")

            return
        }

        do {
            try await kodi.sendVideoUrl(urlString: urlString, server: server)

            actionSuccessAlertMessage = "Your URL should be playing on Kodi"
            showActionSuccessAlert.toggle()

            logManager?.info("URL \(urlString) is playing on Kodi")
        } catch {
            actionErrorAlertMessage = "Kodi Error: \(error)"
            showActionErrorAlert.toggle()

            logManager?.error("Kodi action: \(error)")
        }
    }

    public func installAction(actionJson: ActionJson?, doUpsert: Bool = false) async {
        guard let actionJson else {
            await logManager?.error("Action addition: No action present. Contact the app dev!")
            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext

        if actionJson.requires.count < 1 {
            await logManager?.error("Action addition: actions must require an input. Please contact the action dev!")
            return
        }

        guard let deeplinks = actionJson.deeplink else {
            await logManager?.error("Action addition: only deeplink actions can be added to Ferrite iOS. Please contact the action dev!")
            return
        }

        let existingActionRequest = Action.fetchRequest()
        existingActionRequest.predicate = NSPredicate(format: "name == %@", actionJson.name)
        existingActionRequest.fetchLimit = 1

        if let existingAction = try? backgroundContext.fetch(existingActionRequest).first {
            if doUpsert {
                PersistenceController.shared.delete(existingAction, context: backgroundContext)
            } else {
                await logManager?.error("Action addition: Could not install action with name \(actionJson.name) because it is already installed")

                return
            }
        }

        let newAction = Action(context: backgroundContext)
        newAction.id = UUID()
        newAction.name = actionJson.name
        newAction.version = actionJson.version
        newAction.author = actionJson.author ?? "Unknown"
        newAction.listId = actionJson.listId
        newAction.requires = actionJson.requires.map(\.rawValue)
        newAction.enabled = true

        if let jsonTags = actionJson.tags {
            for tag in jsonTags {
                let newTag = PluginTag(context: backgroundContext)
                newTag.name = tag.name
                newTag.colorHex = tag.colorHex

                newTag.parentAction = newAction
            }
        }

        // Only one deeplink is left in this action JSON because of the previous filtering logic
        guard let deeplinkJson = deeplinks.first else {
            await logManager?.error("Action addition: No deeplink was present in action with name \(actionJson.name). Contact the action dev!")

            return
        }
        newAction.deeplink = deeplinkJson.scheme

        do {
            try backgroundContext.save()
        } catch {
            await logManager?.error("Action addition: \(error)")
        }
    }

    public func installSource(sourceJson: SourceJson?, doUpsert: Bool = false) async {
        guard let sourceJson else {
            await logManager?.error("Source addition: No source present. Contact the app dev!")
            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext

        // If there's no base URL and it isn't dynamic, return before any transactions occur
        let dynamicBaseUrl = sourceJson.dynamicBaseUrl ?? false
        if !dynamicBaseUrl, sourceJson.baseUrl == nil {
            await logManager?.error("Not adding this source because base URL parameters are malformed. Please contact the source dev.")
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
                await logManager?.error("Source addition: Could not install source with name \(sourceJson.name) because it is already installed.")
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
            await logManager?.error("Source addition error: \(error)")
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

        if url.isEmpty || !url.starts(with: "https://") && !url.starts(with: "http://") {
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

//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/28/23.
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.esIsSearching) var isSearching
    @Environment(\.esDismissSearch) var dismissSearch

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var debridManager: DebridManager

    @AppStorage("Behavior.UsesRandomSearchText") var usesRandomSearchText: Bool = false

    @Binding var searchText: String

    var body: some View {
        ForEach(
            scrapingModel.searchResults.sorted {
                navModel.compareSearchResult(lhs: $0, rhs: $1)
            }
            , id: \.self
        ) { result in
            let debridIAStatus = debridManager.matchMagnetHash(result.magnet)
            if
                (pluginManager.filteredInstalledSources.isEmpty ||
                 pluginManager.filteredInstalledSources.contains(where: { result.source == $0.name })) &&
                (debridManager.filteredIAStatus.isEmpty ||
                debridManager.filteredIAStatus.contains(debridIAStatus))
            {
                SearchResultButtonView(result: result)
            }
        }
        .onChange(of: searchText) { newText in
            if newText.isEmpty, isSearching {
                navModel.getSearchPrompt()
            }
        }
        .onChange(of: navModel.selectedTab) { tab in
            // Cancel the search if tab is switched while search is in progress
            if tab != .search, scrapingModel.runningSearchTask != nil {
                scrapingModel.searchResults = []
                scrapingModel.runningSearchTask?.cancel()
                scrapingModel.runningSearchTask = nil
                dismissSearch()
            }
        }
        .onChange(of: scrapingModel.searchResults) { _ in
            // Cleans up any leftover search results in the event of an abrupt cancellation
            if !isSearching {
                scrapingModel.searchResults = []
            }
        }
        .onChange(of: isSearching) { newValue in
            if !newValue {
                scrapingModel.searchResults = []
                scrapingModel.runningSearchTask?.cancel()
                scrapingModel.runningSearchTask = nil
            }
        }
    }
}

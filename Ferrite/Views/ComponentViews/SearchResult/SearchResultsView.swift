//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/28/23.
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.isSearching) var isSearching
    @Environment(\.dismissSearch) var dismissSearch

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("Behavior.UsesRandomSearchText") var usesRandomSearchText: Bool = false

    var body: some View {
        ForEach(scrapingModel.searchResults, id: \.self) { result in
            if result.source == scrapingModel.filteredSource?.name || scrapingModel.filteredSource == nil {
                SearchResultButtonView(result: result)
            }
        }
        .onChange(of: scrapingModel.searchText) { newText in
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
        .overlay {
            if
                scrapingModel.searchResults.isEmpty,
                isSearching,
                scrapingModel.runningSearchTask == nil
            {
                Text("No results found")
            }
        }
    }
}

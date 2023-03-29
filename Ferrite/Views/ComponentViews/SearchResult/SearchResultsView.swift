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

    @Binding var searchText: String

    @Binding var searchPrompt: String
    @State private var lastSearchPromptIndex: Int = -1
    let searchBarTextArray: [String] = [
        "What's on your mind?",
        "Discover something interesting",
        "Find an engaging show",
        "Feeling adventurous?",
        "Look for something new",
        "The classics are a good idea"
    ]

    var body: some View {
        ForEach(scrapingModel.searchResults, id: \.self) { result in
            if result.source == scrapingModel.filteredSource?.name || scrapingModel.filteredSource == nil {
                SearchResultButtonView(result: result)
            }
        }
        .onAppear {
            searchPrompt = getSearchPrompt()
        }
        .onChange(of: searchText) { newText in
            if newText.isEmpty, isSearching {
                searchPrompt = getSearchPrompt()
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

    // Fetches random searchbar text if enabled, otherwise deinit the last case value
    func getSearchPrompt() -> String {
        if usesRandomSearchText {
            let num = Int.random(in: 0 ..< searchBarTextArray.count - 1)
            if num == lastSearchPromptIndex {
                lastSearchPromptIndex = num + 1
                return searchBarTextArray[safe: num + 1] ?? "Search"
            } else {
                lastSearchPromptIndex = num
                return searchBarTextArray[safe: num] ?? "Search"
            }
        } else {
            lastSearchPromptIndex = -1
            return "Search"
        }
    }
}

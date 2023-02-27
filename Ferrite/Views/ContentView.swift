//
//  ContentView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/1/22.
//

import SwiftUI
import SwiftUIX

struct ContentView: View {
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var toastModel: ToastViewModel

    @State private var isEditingSearch = false
    @State private var isSearching = false
    @State private var searchText: String = ""

    var body: some View {
        NavView {
            List {
                ForEach(scrapingModel.searchResults, id: \.self) { result in
                    if result.source == scrapingModel.filteredSource?.name || scrapingModel.filteredSource == nil {
                        SearchResultButtonView(result: result)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .inlinedList(inset: Application.shared.osVersion.majorVersion > 14 ? 20 : -20)
            .overlay {
                if scrapingModel.searchResults.isEmpty && isSearching && scrapingModel.runningSearchTask == nil {
                    Text("No results found")
                }
            }
            .onChange(of: scrapingModel.searchResults) { _ in
                // Cleans up any leftover search results in the event of an abrupt cancellation
                if !isSearching {
                    scrapingModel.searchResults = []
                }
            }
            .onChange(of: navModel.selectedTab) { tab in
                // Cancel the search if tab is switched while search is in progress
                if tab != .search, scrapingModel.runningSearchTask != nil {
                    scrapingModel.searchResults = []
                    scrapingModel.runningSearchTask?.cancel()
                    scrapingModel.runningSearchTask = nil
                    isSearching = false
                    searchText = ""
                }
            }
            .navigationTitle("Search")
            .navigationSearchBar {
                SearchBar(
                    "Search",
                    text: $searchText,
                    isEditing: $isEditingSearch,
                    onCommit: {
                        if let runningSearchTask = scrapingModel.runningSearchTask, runningSearchTask.isCancelled {
                            scrapingModel.runningSearchTask = nil
                            return
                        }

                        scrapingModel.runningSearchTask = Task {
                            isSearching = true

                            let sources = pluginManager.fetchInstalledSources()
                            await scrapingModel.scanSources(sources: sources, searchText: searchText)

                            if debridManager.enabledDebrids.count > 0, !scrapingModel.searchResults.isEmpty {
                                debridManager.clearIAValues()

                                let magnets = scrapingModel.searchResults.map(\.magnet)
                                await debridManager.populateDebridIA(magnets)
                            }

                            toastModel.hideIndeterminateToast()
                            scrapingModel.runningSearchTask = nil
                        }
                    }
                )
                .showsCancelButton(isEditingSearch || isSearching)
                .onCancel {
                    scrapingModel.searchResults = []
                    scrapingModel.runningSearchTask?.cancel()
                    scrapingModel.runningSearchTask = nil
                    isSearching = false
                    searchText = ""
                }
            }
            .navigationSearchBarHiddenWhenScrolling(false)
        }
        .customScopeBar {
            SearchFilterHeaderView()
                .environmentObject(scrapingModel)
                .environmentObject(debridManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

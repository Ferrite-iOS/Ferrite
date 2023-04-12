//
//  ContentView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/1/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var logManager: LoggingManager

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch: Bool = false

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isEditingSearch = false
    @State private var dismissAction: () -> Void = {}

    var body: some View {
        NavView {
            List {
                SearchResultsView(searchText: $searchText)
            }
            .listStyle(.insetGrouped)
            .inlinedList(inset: 20)
            .navigationTitle("Search")
            .overlay {
                if
                    scrapingModel.searchResults.isEmpty,
                    isSearching,
                    scrapingModel.runningSearchTask == nil,
                    !isEditingSearch
                {
                    Text(
                        pluginManager.filteredInstalledSources.isEmpty ?
                            "No results found" :
                            "No results found. Check your source filter and redo your search."
                    )
                    .padding(.horizontal)
                }
            }
            .expandedSearchable(
                text: $searchText,
                isSearching: $isSearching,
                isEditingSearch: $isEditingSearch,
                prompt: navModel.searchPrompt,
                dismiss: $dismissAction,
                scopeBarContent: {
                    SearchFilterHeaderView()
                },
                onSubmit: {
                    if
                        let runningSearchTask = scrapingModel.runningSearchTask,
                        runningSearchTask.isCancelled
                    {
                        scrapingModel.runningSearchTask = nil
                        return
                    }

                    executeSearch()
                }
            )
            .autocorrectionDisabled(!autocorrectSearch)
            .esAutocapitalization(autocorrectSearch ? .sentences : .none)
            .onAppear {
                navModel.getSearchPrompt()
            }
        }
    }

    func executeSearch() {
        scrapingModel.runningSearchTask = Task {
            await scrapingModel.scanSources(
                sources: pluginManager.fetchInstalledSources(
                    searchResultsEmpty: scrapingModel.searchResults.isEmpty
                ),
                searchText: searchText,
                debridManager: debridManager
            )

            logManager.hideIndeterminateToast()
            scrapingModel.runningSearchTask = nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

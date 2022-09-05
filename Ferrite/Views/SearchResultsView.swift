//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SearchResultsView: View {
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    var body: some View {
        List {
            ForEach(scrapingModel.searchResults, id: \.self) { result in
                if result.source == scrapingModel.filteredSource?.name || scrapingModel.filteredSource == nil {
                    SearchResultButtonView(result: result)
                }
            }
        }
        .listStyle(.insetGrouped)
        .inlinedList()
        .overlay {
            if scrapingModel.searchResults.isEmpty {
                if navModel.showSearchProgress {
                    VStack(spacing: 5) {
                        ProgressView()
                        Text("Loading \(scrapingModel.currentSourceName ?? "")")
                    }
                } else if navModel.isSearching, scrapingModel.runningSearchTask != nil {
                    Text("No results found")
                }
            }
        }
        .onChange(of: navModel.selectedTab) { tab in
            // Cancel the search if tab is switched while search is in progress
            if tab != .search, navModel.showSearchProgress {
                scrapingModel.searchResults = []
                scrapingModel.runningSearchTask?.cancel()
                scrapingModel.runningSearchTask = nil
                navModel.isSearching = false
                scrapingModel.searchText = ""
            }
        }
        .onChange(of: scrapingModel.searchResults) { _ in
            // Cleans up any leftover search results in the event of an abrupt cancellation
            if !navModel.isSearching {
                scrapingModel.searchResults = []
            }
        }
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
    }
}

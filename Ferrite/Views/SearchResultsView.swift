//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.isSearching) var isSearching
    @Environment(\.dismissSearch) var dismissSearch

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    var body: some View {
        List {
            ForEach(scrapingModel.searchResults, id: \.self) { result in
                if result.source == scrapingModel.filteredSource?.name || scrapingModel.filteredSource == nil {
                    VStack(alignment: .leading) {
                        Button {
                            scrapingModel.selectedSearchResult = result

                            switch debridManager.matchSearchResult(result: result) {
                            case .full:
                                Task {
                                    await debridManager.fetchRdDownload(searchResult: result)
                                    navModel.runDebridAction(action: nil, urlString: debridManager.realDebridDownloadUrl)
                                }
                            case .partial:
                                if debridManager.setSelectedRdResult(result: result) {
                                    navModel.currentChoiceSheet = .batch
                                }
                            case .none:
                                navModel.runMagnetAction(action: nil, searchResult: result)
                            }
                        } label: {
                            Text(result.title)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tint(.primary)
                        .padding(.bottom, 5)

                        SearchResultRDView(result: result)
                    }
                }
            }
        }
        .overlay {
            if scrapingModel.searchResults.isEmpty, navModel.showSearchProgress {
                VStack(spacing: 5) {
                    ProgressView()
                    Text("Loading \(scrapingModel.currentSourceName ?? "")")
                }
            }
        }
        .onChange(of: navModel.selectedTab) { tab in
            // Cancel the search if tab is switched
            if tab != .search, isSearching, navModel.showSearchProgress {
                scrapingModel.runningSearchTask?.cancel()
                dismissSearch()
            }
        }
        .onChange(of: isSearching) { changed in
            // Clear the results array on cancel
            if !changed {
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

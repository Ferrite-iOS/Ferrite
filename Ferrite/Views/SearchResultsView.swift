//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.isSearching) var isSearching

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navigationModel: NavigationViewModel

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
                                    navigationModel.currentChoiceSheet = .magnet
                                }
                            case .partial:
                                if debridManager.setSelectedRdResult(result: result) {
                                    navigationModel.currentChoiceSheet = .batch
                                }
                            case .none:
                                navigationModel.currentChoiceSheet = .magnet
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
        .onChange(of: isSearching) { changed in
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

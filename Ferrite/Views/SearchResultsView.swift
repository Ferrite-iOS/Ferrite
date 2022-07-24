//
//  SearchResultsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.isSearching) var isSearching
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navigationModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    var body: some View {
        List {
            ForEach(scrapingModel.searchResults, id: \.self) { result in
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
                    .sheet(item: $navigationModel.currentChoiceSheet) { item in
                        switch item {
                        case .magnet:
                            MagnetChoiceView()
                        case .batch:
                            BatchChoiceView()
                        }
                    }
                    .tint(colorScheme == .light ? .black : .white)
                    .padding(.bottom, 5)

                    HStack {
                        Text(result.source)

                        Spacer()

                        Text(result.size)

                        if realDebridEnabled {
                            Text("RD")
                                .fontWeight(.bold)
                                .padding(2)
                                .background {
                                    switch debridManager.matchSearchResult(result: result) {
                                    case .full:
                                        Color.green
                                            .cornerRadius(4)
                                            .opacity(0.5)
                                    case .partial:
                                        Color.orange
                                            .cornerRadius(4)
                                            .opacity(0.5)
                                    case .none:
                                        Color.red
                                            .cornerRadius(4)
                                            .opacity(0.5)
                                    }
                                }
                        }
                    }
                    .font(.caption)
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

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

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @FetchRequest(
        entity: TorrentSource.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<TorrentSource>

    @State private var selectedSource: TorrentSource? {
        didSet {
            scrapingModel.filteredSource = selectedSource
        }
    }

    var body: some View {
        NavView {
            VStack(spacing: 10) {
                HStack {
                    Text("Filter")
                        .foregroundColor(.secondary)

                    Menu {
                        Button {
                            selectedSource = nil
                        } label: {
                            Text("None")

                            if selectedSource == nil {
                                Image(systemName: "checkmark")
                            }
                        }

                        ForEach(sources, id: \.self) { source in
                            if let name = source.name, source.enabled {
                                Button {
                                    selectedSource = source
                                } label: {
                                    Text(name)

                                    if selectedSource == source {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(selectedSource?.name ?? "Source")
                            .padding(.trailing, -3)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 20)

                SearchResultsView()
            }
            .searchable(text: $scrapingModel.searchText)
            .onSubmit(of: .search) {
                Task {
                    await scrapingModel.scanSources(sources: sources.compactMap { $0 })
                    await debridManager.populateDebridHashes(scrapingModel.searchResults)
                }
            }
            .navigationTitle("Search")
        }
    }

    func performSearch() {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

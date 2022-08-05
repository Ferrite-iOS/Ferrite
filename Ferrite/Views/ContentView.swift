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
    @EnvironmentObject var navigationModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    @State private var selectedSource: Source? {
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

                    if realDebridEnabled {
                        await debridManager.populateDebridHashes(scrapingModel.searchResults)
                    }
                }
            }
            .navigationTitle("Search")
        }
        .sheet(item: $navigationModel.currentChoiceSheet) { item in
            Group {
                switch item {
                case .magnet:
                    MagnetChoiceView()
                case .batch:
                    BatchChoiceView()
                }
            }
            .tint(.primary)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

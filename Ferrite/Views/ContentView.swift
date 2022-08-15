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
                .padding(.vertical, 5)
                .padding(.horizontal, 20)

                SearchResultsView()
            }
            .sheet(item: $navModel.currentChoiceSheet) { item in
                Group {
                    switch item {
                    case .magnet:
                        MagnetChoiceView()
                            .environmentObject(debridManager)
                            .environmentObject(scrapingModel)
                            .environmentObject(navModel)
                    case .batch:
                        BatchChoiceView()
                            .environmentObject(debridManager)
                            .environmentObject(scrapingModel)
                            .environmentObject(navModel)
                    }
                }
                .dynamicAccentColor(.primary)
            }
            .sheet(isPresented: $navModel.showActivityView) {
                if #available(iOS 16, *) {
                    AppActivityView(activityItems: navModel.activityItems)
                        .presentationDetents([.medium])
                } else {
                    AppActivityView(activityItems: navModel.activityItems)
                }
            }
            .navigationTitle("Search")
            .navigationSearchBar {
                SearchBar("Search", text: $scrapingModel.searchText, isEditing: $navModel.isEditingSearch,
                          onCommit: {
                              scrapingModel.runningSearchTask = Task {
                                  navModel.isSearching = true
                                  navModel.showSearchProgress = true

                                  await scrapingModel.scanSources(sources: sources.compactMap { $0 })

                                  if realDebridEnabled, !scrapingModel.searchResults.isEmpty {
                                      await debridManager.populateDebridHashes(scrapingModel.searchResults)
                                  }

                                  navModel.showSearchProgress = false
                              }
                          })
                          .showsCancelButton(navModel.isEditingSearch || navModel.isSearching)
                          .onCancel {
                              scrapingModel.searchResults = []
                              scrapingModel.runningSearchTask?.cancel()
                              scrapingModel.runningSearchTask = nil
                              navModel.isSearching = false
                              scrapingModel.searchText = ""
                          }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

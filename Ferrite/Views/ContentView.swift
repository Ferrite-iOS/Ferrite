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
    @EnvironmentObject var sourceManager: SourceManager

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
                HStack(spacing: 6) {
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
                                    if selectedSource == source {
                                        Label(name, systemImage: "checkmark")
                                    } else {
                                        Text(name)
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
                    .animation(.none)

                    Spacer()
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 20)

                SearchResultsView()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(navModel.isSearching ? .inline : .large)
            .navigationSearchBar {
                SearchBar("Search",
                          text: $scrapingModel.searchText,
                          isEditing: $navModel.isEditingSearch,
                          onCommit: {
                              scrapingModel.searchResults = []
                              scrapingModel.runningSearchTask = Task {
                                  navModel.isSearching = true
                                  navModel.showSearchProgress = true

                                  let sources = sourceManager.fetchInstalledSources()
                                  await scrapingModel.scanSources(sources: sources)

                                  if debridManager.enabledDebrids.count > 0, !scrapingModel.searchResults.isEmpty {
                                      debridManager.clearIAValues()

                                      // Remove magnets that don't have a hash
                                      let magnets = scrapingModel.searchResults.compactMap {
                                          if let magnetHash = $0.magnet.hash {
                                              return Magnet(hash: magnetHash, link: $0.magnet.link)
                                          } else {
                                              return nil
                                          }
                                      }
                                      await debridManager.populateDebridIA(magnets)
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
            .introspectSearchController { searchController in
                searchController.hidesNavigationBarDuringPresentation = false
                searchController.searchBar.autocorrectionType = .no
                searchController.searchBar.autocapitalizationType = .none
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    DebridChoiceView()
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

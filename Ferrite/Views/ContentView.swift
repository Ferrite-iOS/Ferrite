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

    var body: some View {
        NavView {
            SearchResultsView()
                .listStyle(.insetGrouped)
                .navigationTitle("Search")
                .navigationSearchBar {
                    SearchBar("Search",
                              text: $scrapingModel.searchText,
                              isEditing: $navModel.isEditingSearch,
                              onCommit: {
                                  scrapingModel.searchResults = []
                                  scrapingModel.runningSearchTask = Task {
                                      navModel.isSearching = true
                                      navModel.showSearchProgress = true

                                      let sources = pluginManager.fetchInstalledSources()
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
                .navigationSearchBarHiddenWhenScrolling(false)
                .searchAppearance {
                    SearchFilterHeaderView()
                        .environmentObject(scrapingModel)
                        .environmentObject(debridManager)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

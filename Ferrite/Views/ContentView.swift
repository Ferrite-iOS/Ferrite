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

    // TODO: Fix searchPrompt updating
    @State private var searchPrompt: String = "Search"

    var body: some View {
        NavView {
            List {
                SearchResultsView(searchPrompt: $searchPrompt)
            }
            .listStyle(.insetGrouped)
            .inlinedList(inset: 20)
            .navigationTitle("Search")
            .searchable(text: $scrapingModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(searchPrompt))
            .onSubmit(of: .search) {
                if let runningSearchTask = scrapingModel.runningSearchTask, runningSearchTask.isCancelled {
                    scrapingModel.runningSearchTask = nil
                    return
                }

                scrapingModel.runningSearchTask = Task {
                    let sources = pluginManager.fetchInstalledSources()
                    await scrapingModel.scanSources(
                        sources: sources,
                        debridManager: debridManager
                    )

                    logManager.hideIndeterminateToast()
                    scrapingModel.runningSearchTask = nil
                }
            }
            .customScopeBar {
                SearchFilterHeaderView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

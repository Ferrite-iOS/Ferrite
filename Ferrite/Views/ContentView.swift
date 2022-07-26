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

    var body: some View {
        NavView {
            VStack {
                SearchResultsView()
            }
            .searchable(text: $scrapingModel.searchText)
            .onSubmit(of: .search) {
                Task {
                    await scrapingModel.scanSources(sources: sources)
                    await debridManager.populateDebridHashes(scrapingModel.searchResults)
                }
            }
            .navigationTitle("Search")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

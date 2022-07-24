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

    var body: some View {
        NavView {
            VStack {
                SearchResultsView()
            }
            .searchable(text: $scrapingModel.searchText)
            .onSubmit(of: .search) {
                Task {
                    for source in scrapingModel.sources {
                        guard let html = await scrapingModel.fetchWebsiteHtml(source: source) else {
                            continue
                        }

                        await scrapingModel.scrapeWebsite(source: source, html: html)

                        if realDebridEnabled {
                            await debridManager.populateDebridHashes(scrapingModel.searchResults)
                        }
                    }
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

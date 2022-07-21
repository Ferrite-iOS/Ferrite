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

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @State var selectedResult: SearchResult?

    @State private var showExternalSheet = false

    var body: some View {
        List {
            ForEach(scrapingModel.searchResults, id: \.self) { result in
                VStack(alignment: .leading) {
                    Button(result.title) {
                        selectedResult = result

                        if debridManager.realDebridHashes.contains(result.magnetHash ?? ""), realDebridEnabled {
                            Task {
                                await debridManager.fetchRdDownload(searchResult: result)
                                showExternalSheet.toggle()
                            }
                        } else {
                            showExternalSheet.toggle()
                        }
                    }
                    .sheet(isPresented: $showExternalSheet) {
                        MagnetChoiceView(selectedResult: $selectedResult)
                    }
                    .tint(colorScheme == .light ? .black : .white)
                    .font(.callout)
                    .padding(.bottom, 5)

                    HStack {
                        if realDebridEnabled {
                            Text("Real Debrid available: \(debridManager.realDebridHashes.contains(result.magnetHash ?? "") ? "Yes" : "No")")
                        }

                        Spacer()
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

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
    @State private var resultUsesRd = false

    var body: some View {
        List {
            ForEach(scrapingModel.searchResults, id: \.self) { result in
                VStack(alignment: .leading) {
                    Button {
                        selectedResult = result

                        if debridManager.realDebridHashes.contains(result.magnetHash ?? ""), realDebridEnabled {
                            Task {
                                await debridManager.fetchRdDownload(searchResult: result)
                                showExternalSheet.toggle()
                            }
                        } else {
                            showExternalSheet.toggle()
                        }
                    } label: {
                        Text(result.title)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .sheet(isPresented: $showExternalSheet) {
                        MagnetChoiceView(selectedResult: $selectedResult)
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
                                    if debridManager.realDebridHashes.contains(result.magnetHash ?? "") {
                                        Color.green
                                            .cornerRadius(4)
                                            .opacity(0.5)
                                    } else {
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

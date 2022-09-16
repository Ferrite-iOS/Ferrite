//
//  BatchChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct BatchChoiceView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    var body: some View {
        NavView {
            List {
                ForEach(debridManager.selectedRealDebridItem?.files ?? [], id: \.self) { file in
                    Button(file.name) {
                        debridManager.selectedRealDebridFile = file

                        if let searchResult = navModel.selectedSearchResult {
                            debridManager.currentDebridTask = Task {
                                await debridManager.fetchRdDownload(searchResult: searchResult)

                                if !debridManager.realDebridDownloadUrl.isEmpty {
                                    // The download may complete before this sheet dismisses
                                    try? await Task.sleep(seconds: 1)
                                    navModel.addToHistory(name: searchResult.title, source: searchResult.source, url: debridManager.realDebridDownloadUrl, subName: file.name)
                                    navModel.runDebridAction(urlString: debridManager.realDebridDownloadUrl)
                                }

                                debridManager.selectedRealDebridFile = nil
                                debridManager.selectedRealDebridItem = nil
                            }
                        }

                        navModel.currentChoiceSheet = nil
                    }
                    .dynamicAccentColor(.primary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select a file")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        navModel.currentChoiceSheet = nil

                        Task {
                            try? await Task.sleep(seconds: 1)
                            debridManager.selectedRealDebridItem = nil
                        }
                    }
                }
            }
        }
    }
}

struct BatchChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        BatchChoiceView()
    }
}

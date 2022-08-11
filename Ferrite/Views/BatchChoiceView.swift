//
//  BatchChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct BatchChoiceView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        NavView {
            List {
                ForEach(debridManager.selectedRealDebridItem?.files ?? [], id: \.self) { file in
                    Button(file.name) {
                        debridManager.selectedRealDebridFile = file

                        if let searchResult = scrapingModel.selectedSearchResult {
                            Task {
                                await debridManager.fetchRdDownload(searchResult: searchResult, iaFile: file)

                                // The download may complete before this sheet dismisses
                                try? await Task.sleep(seconds: 1)
                                navModel.runDebridAction(action: nil, urlString: debridManager.realDebridDownloadUrl)

                                debridManager.selectedRealDebridFile = nil
                                debridManager.selectedRealDebridItem = nil
                            }
                        }

                        dismiss()
                    }
                }
            }
            .navigationTitle("Select a file")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        debridManager.selectedRealDebridItem = nil

                        dismiss()
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

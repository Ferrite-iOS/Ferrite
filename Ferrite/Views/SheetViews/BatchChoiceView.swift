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
    @EnvironmentObject var pluginManager: PluginManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @State private var searchText: String = ""

    // TODO: Make this generic for an IA protocol
    var body: some View {
        NavView {
            List {
                switch debridManager.selectedDebridType {
                case .realDebrid:
                    ForEach(debridManager.selectedRealDebridItem?.files ?? [], id: \.self) { file in
                        if file.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty {
                            Button(file.name) {
                                debridManager.selectedRealDebridFile = file

                                queueCommonDownload(fileName: file.name)
                            }
                        }
                    }
                case .allDebrid:
                    ForEach(debridManager.selectedAllDebridItem?.files ?? [], id: \.self) { file in
                        if file.fileName.lowercased().contains(searchText.lowercased()) || searchText.isEmpty {
                            Button(file.fileName) {
                                debridManager.selectedAllDebridFile = file

                                queueCommonDownload(fileName: file.fileName)
                            }
                        }
                    }
                case .premiumize:
                    ForEach(debridManager.selectedPremiumizeItem?.files ?? [], id: \.self) { file in
                        if file.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty {
                            Button(file.name) {
                                debridManager.selectedPremiumizeFile = file

                                queueCommonDownload(fileName: file.name)
                            }
                        }
                    }
                case .none:
                    EmptyView()
                }
            }
            .tint(.primary)
            .listStyle(.insetGrouped)
            .inlinedList(inset: -20)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .autocorrectionDisabled(!autocorrectSearch)
            .textInputAutocapitalization(autocorrectSearch ? .sentences : .never)
            .navigationTitle("Select a file")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        navModel.currentChoiceSheet = nil

                        Task {
                            try? await Task.sleep(seconds: 1)

                            debridManager.clearSelectedDebridItems()
                        }
                    }
                }
            }
        }
    }

    // Common function to communicate betwen VMs and queue/display a download
    func queueCommonDownload(fileName: String) {
        debridManager.currentDebridTask = Task {
            await debridManager.fetchDebridDownload(magnet: navModel.resultFromCloud ? nil : navModel.selectedMagnet)

            if !debridManager.downloadUrl.isEmpty {
                try? await Task.sleep(seconds: 1)
                navModel.selectedBatchTitle = fileName

                if var selectedHistoryInfo = navModel.selectedHistoryInfo {
                    selectedHistoryInfo.url = debridManager.downloadUrl
                    selectedHistoryInfo.subName = fileName
                    PersistenceController.shared.createHistory(selectedHistoryInfo, performSave: true)
                }

                pluginManager.runDefaultAction(
                    urlString: debridManager.downloadUrl,
                    navModel: navModel
                )
            }

            debridManager.clearSelectedDebridItems()
        }

        navModel.currentChoiceSheet = nil
    }
}

struct BatchChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        BatchChoiceView()
    }
}

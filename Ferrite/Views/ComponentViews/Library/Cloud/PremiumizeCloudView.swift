//
//  PremiumizeCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/2/23.
//

import SwiftUI

struct PremiumizeCloudView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager

    @Binding var searchText: String

    var body: some View {
        DisclosureGroup("Items") {
            ForEach(debridManager.premiumizeCloudItems.filter {
                searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
            }, id: \.id) { item in
                Button(item.name) {
                    Task {
                        navModel.resultFromCloud = true
                        navModel.selectedTitle = item.name

                        await debridManager.fetchDebridDownload(magnet: nil, cloudInfo: item.id)

                        if !debridManager.downloadUrl.isEmpty {
                            PersistenceController.shared.createHistory(
                                HistoryEntryJson(
                                    name: item.name,
                                    url: debridManager.downloadUrl,
                                    source: DebridType.premiumize.toString()
                                ),
                                performSave: true
                            )

                            pluginManager.runDefaultAction(
                                urlString: debridManager.downloadUrl,
                                navModel: navModel
                            )
                        }
                    }
                }
                .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
                .tint(.primary)
            }
            .onDelete { offsets in
                for index in offsets {
                    if let item = debridManager.premiumizeCloudItems[safe: index] {
                        Task {
                            await debridManager.deletePmItem(id: item.id)
                        }
                    }
                }
            }
        }
    }
}

//
//  PremiumizeCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/2/23.
//

import SwiftUI
import SwiftUIX

struct PremiumizeCloudView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    @State private var viewTask: Task<Void, Never>?

    var body: some View {
        DisclosureGroup("Items") {
            ForEach(debridManager.premiumizeCloudItems, id: \.id) { item in
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
                                )
                            )

                            navModel.runDebridAction(urlString: debridManager.downloadUrl)
                        }
                    }
                }
                .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
                .backport.tint(.black)
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
        .onAppear {
            viewTask = Task {
                await debridManager.fetchPmCloud()
            }
        }
        .onDisappear {
            viewTask?.cancel()
        }
    }
}

struct PremiumizeCloudView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumizeCloudView()
    }
}

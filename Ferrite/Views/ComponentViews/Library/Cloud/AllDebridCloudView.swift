//
//  AllDebridCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/5/23.
//

import SwiftUI

struct AllDebridCloudView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager

    @Binding var searchText: String

    var body: some View {
        DisclosureGroup("Links") {
            ForEach(debridManager.allDebridCloudLinks.filter {
                searchText.isEmpty ? true : $0.filename.lowercased().contains(searchText.lowercased())
            }, id: \.self) { downloadResponse in
                Button(downloadResponse.filename) {
                    navModel.resultFromCloud = true
                    navModel.selectedTitle = downloadResponse.filename
                    debridManager.downloadUrl = downloadResponse.link

                    PersistenceController.shared.createHistory(
                        HistoryEntryJson(
                            name: downloadResponse.filename,
                            url: downloadResponse.link,
                            source: DebridType.allDebrid.toString()
                        ),
                        performSave: true
                    )

                    pluginManager.runDefaultAction(
                        urlString: debridManager.downloadUrl,
                        navModel: navModel
                    )
                }
                .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
                .tint(.primary)
            }
            .onDelete { offsets in
                for index in offsets {
                    if let savedLink = debridManager.allDebridCloudLinks[safe: index] {
                        Task {
                            await debridManager.deleteAdLink(link: savedLink.link)
                        }
                    }
                }
            }
        }

        DisclosureGroup("Magnets") {
            ForEach(debridManager.allDebridCloudMagnets.filter {
                searchText.isEmpty ? true : $0.filename.lowercased().contains(searchText.lowercased())
            }, id: \.id) { magnet in
                Button {
                    if magnet.status == "Ready", !magnet.links.isEmpty {
                        navModel.resultFromCloud = true
                        navModel.selectedTitle = magnet.filename

                        var historyInfo = HistoryEntryJson(
                            name: magnet.filename,
                            source: DebridType.allDebrid.toString()
                        )

                        Task {
                            if magnet.links.count == 1 {
                                if let lockedLink = magnet.links[safe: 0]?.link {
                                    await debridManager.fetchDebridDownload(magnet: nil, cloudInfo: lockedLink)

                                    if !debridManager.downloadUrl.isEmpty {
                                        historyInfo.url = debridManager.downloadUrl
                                        PersistenceController.shared.createHistory(historyInfo, performSave: true)
                                        pluginManager.runDefaultAction(
                                            urlString: debridManager.downloadUrl,
                                            navModel: navModel
                                        )
                                    }
                                }
                            } else {
                                let magnet = Magnet(hash: magnet.hash, link: nil)

                                // Do not clear old IA values
                                await debridManager.populateDebridIA([magnet])

                                if debridManager.selectDebridResult(magnet: magnet) {
                                    navModel.selectedHistoryInfo = historyInfo
                                    navModel.currentChoiceSheet = .batch
                                }
                            }
                        }
                    }

                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(magnet.filename)

                        HStack {
                            Text(magnet.status)
                            Spacer()
                            DebridLabelView(cloudLinks: magnet.links.map(\.link))
                        }
                        .font(.caption)
                    }
                }
                .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.9, animation: .easeOut(duration: 0.2))
                .tint(.primary)
            }
            .onDelete { offsets in
                for index in offsets {
                    if let magnet = debridManager.allDebridCloudMagnets[safe: index] {
                        Task {
                            await debridManager.deleteAdMagnet(magnetId: magnet.id)
                        }
                    }
                }
            }
        }
    }
}

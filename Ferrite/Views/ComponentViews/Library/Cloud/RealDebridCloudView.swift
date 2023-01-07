//
//  RealDebridCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/31/22.
//

import SwiftUI

struct RealDebridCloudView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    @Binding var searchText: String

    @State private var viewTask: Task<Void, Never>?

    var body: some View {
        Group {
            DisclosureGroup("Downloads") {
                ForEach(debridManager.realDebridCloudDownloads.filter {
                    searchText.isEmpty ? true : $0.filename.lowercased().contains(searchText.lowercased())
                }, id: \.self) { downloadResponse in
                    Button(downloadResponse.filename) {
                        navModel.resultFromCloud = true
                        navModel.selectedTitle = downloadResponse.filename
                        debridManager.downloadUrl = downloadResponse.download

                        PersistenceController.shared.createHistory(
                            HistoryEntryJson(
                                name: downloadResponse.filename,
                                url: downloadResponse.download,
                                source: DebridType.realDebrid.toString()
                            )
                        )

                        navModel.runDebridAction(urlString: debridManager.downloadUrl)
                    }
                    .backport.tint(.primary)
                }
                .onDelete { offsets in
                    for index in offsets {
                        if let downloadResponse = debridManager.realDebridCloudDownloads[safe: index] {
                            Task {
                                await debridManager.deleteRdDownload(downloadID: downloadResponse.id)
                            }
                        }
                    }
                }
            }

            DisclosureGroup("Torrents") {
                ForEach(debridManager.realDebridCloudTorrents.filter {
                    searchText.isEmpty ? true : $0.filename.lowercased().contains(searchText.lowercased())
                }, id: \.self) { torrentResponse in
                    Button {
                        if torrentResponse.status == "downloaded" && !torrentResponse.links.isEmpty {
                            navModel.resultFromCloud = true
                            navModel.selectedTitle = torrentResponse.filename

                            var historyInfo = HistoryEntryJson(
                                name: torrentResponse.filename,
                                source: DebridType.realDebrid.toString()
                            )

                            Task {
                                if torrentResponse.links.count == 1 {
                                    if let torrentLink = torrentResponse.links[safe: 0] {
                                        await debridManager.fetchDebridDownload(magnet: nil, cloudInfo: torrentLink)
                                        if !debridManager.downloadUrl.isEmpty {
                                            historyInfo.url = debridManager.downloadUrl
                                            PersistenceController.shared.createHistory(historyInfo)

                                            navModel.runDebridAction(urlString: debridManager.downloadUrl)
                                        }
                                    }
                                } else {
                                    let magnet = Magnet(hash: torrentResponse.hash, link: nil)

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
                            Text(torrentResponse.filename)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(4)

                            HStack {
                                Text(torrentResponse.status.capitalizingFirstLetter())
                                Spacer()
                                DebridLabelView(cloudLinks: torrentResponse.links)
                            }
                            .font(.caption)
                        }
                    }
                    .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
                    .backport.tint(.primary)
                }
                .onDelete { offsets in
                    for index in offsets {
                        if let torrentResponse = debridManager.realDebridCloudTorrents[safe: index] {
                            Task {
                                await debridManager.deleteRdTorrent(torrentID: torrentResponse.id)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewTask = Task {
                await debridManager.fetchRdCloud()
            }
        }
        .onDisappear {
            viewTask?.cancel()
        }
    }
}

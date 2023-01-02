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

    @State private var viewTask: Task<Void, Never>?

    var body: some View {
        Group {
            DisclosureGroup("Downloads") {
                ForEach(debridManager.realDebridCloudDownloads, id: \.self) { downloadResponse in
                    Button(downloadResponse.filename) {
                        navModel.resultFromCloud = true
                        navModel.selectedTitle = downloadResponse.filename
                        debridManager.downloadUrl = downloadResponse.link

                        PersistenceController.shared.createHistory(
                            HistoryEntryJson(
                                name: downloadResponse.filename,
                                url: downloadResponse.link,
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
                                do {
                                    try await debridManager.realDebrid.deleteDownload(debridID: downloadResponse.id)

                                    // Bypass TTL to get current RD values
                                    await debridManager.fetchRdCloud(bypassTTL: true)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }

            DisclosureGroup("Torrents") {
                ForEach(debridManager.realDebridCloudTorrents, id: \.self) { torrentResponse in
                    Button {
                        Task {
                            if torrentResponse.status == "downloaded" && !torrentResponse.links.isEmpty {
                                navModel.resultFromCloud = true
                                navModel.selectedTitle = torrentResponse.filename

                                var historyInfo = HistoryEntryJson(
                                    name: torrentResponse.filename,
                                    source: DebridType.realDebrid.toString()
                                )

                                if torrentResponse.links.count == 1 {
                                    if let downloadLink = torrentResponse.links[safe: 0] {
                                        do {
                                            try await debridManager.checkRdUserDownloads(userTorrentLink: downloadLink)
                                            navModel.selectedTitle = torrentResponse.filename
                                            historyInfo.url = downloadLink

                                            PersistenceController.shared.createHistory(historyInfo)
                                            navModel.currentChoiceSheet = .magnet
                                        } catch {
                                            debridManager.toastModel?.updateToastDescription("RealDebrid cloud fetch error: \(error)")
                                        }
                                    }
                                } else {
                                    debridManager.clearIAValues()
                                    await debridManager.populateDebridIA([Magnet(link: nil, hash: torrentResponse.hash)])

                                    if debridManager.selectDebridResult(magnetHash: torrentResponse.hash) {
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
                                do {
                                    try await debridManager.realDebrid.deleteTorrent(debridID: torrentResponse.id)

                                    // Bypass TTL to get current RD values
                                    await debridManager.fetchRdCloud(bypassTTL: true)
                                } catch {
                                    print(error)
                                }
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

struct RealDebridCloudView_Previews: PreviewProvider {
    static var previews: some View {
        RealDebridCloudView()
    }
}

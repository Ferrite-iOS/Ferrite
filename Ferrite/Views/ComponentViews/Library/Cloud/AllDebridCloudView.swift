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

    @State private var viewTask: Task<Void, Never>?

    var body: some View {
        DisclosureGroup("Magnets") {
            ForEach(debridManager.allDebridCloudMagnets, id: \.id) { magnet in
                Button {
                    if magnet.status == "Ready" && !magnet.links.isEmpty {
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
                                        PersistenceController.shared.createHistory(historyInfo)
                                        navModel.runDebridAction(urlString: debridManager.downloadUrl)
                                    }
                                }
                            } else {
                                debridManager.clearIAValues()
                                let magnet = Magnet(hash: magnet.hash, link: nil)
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
                .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
                .backport.tint(.black)
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
        .onAppear {
            viewTask = Task {
                await debridManager.fetchAdCloud()
            }
        }
        .onDisappear {
            viewTask?.cancel()
        }
    }
}

struct AllDebridCloudView_Previews: PreviewProvider {
    static var previews: some View {
        AllDebridCloudView()
    }
}
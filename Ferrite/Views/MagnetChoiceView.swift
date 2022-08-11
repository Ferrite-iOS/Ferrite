//
//  MagnetChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import ActivityView
import SwiftUI

struct MagnetChoiceView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @State private var showActivityView = false
    @State private var showLinkCopyAlert = false
    @State private var showMagnetCopyAlert = false
    @State private var activityItem: ActivityItem?

    var body: some View {
        NavView {
            Form {
                if realDebridEnabled, debridManager.matchSearchResult(result: scrapingModel.selectedSearchResult) != .none {
                    Section("Real Debrid options") {
                        ListRowButtonView("Play on Outplayer", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(action: .outplayer, urlString: debridManager.realDebridDownloadUrl)
                        }

                        ListRowButtonView("Play on VLC", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(action: .vlc, urlString: debridManager.realDebridDownloadUrl)
                        }

                        ListRowButtonView("Play on Infuse", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(action: .infuse, urlString: debridManager.realDebridDownloadUrl)
                        }

                        ListRowButtonView("Copy download URL", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = debridManager.realDebridDownloadUrl
                            showLinkCopyAlert.toggle()
                        }
                        .alert(isPresented: $showLinkCopyAlert) {
                            Alert(
                                title: Text("Copied"),
                                message: Text("Download link copied successfully"),
                                dismissButton: .cancel(Text("OK"))
                            )
                        }

                        ListRowButtonView("Share download URL", systemImage: "square.and.arrow.up.fill") {
                            guard let url = URL(string: debridManager.realDebridDownloadUrl) else {
                                return
                            }

                            activityItem = ActivityItem(items: url)
                        }
                    }
                }

                Section("Magnet options") {
                    ListRowButtonView("Copy magnet", systemImage: "doc.on.doc.fill") {
                        UIPasteboard.general.string = scrapingModel.selectedSearchResult?.magnetLink
                        showMagnetCopyAlert.toggle()
                    }
                    .alert(isPresented: $showMagnetCopyAlert) {
                        Alert(
                            title: Text("Copied"),
                            message: Text("Magnet link copied successfully"),
                            dismissButton: .cancel(Text("OK"))
                        )
                    }

                    ListRowButtonView("Share magnet", systemImage: "square.and.arrow.up.fill") {
                        if let result = scrapingModel.selectedSearchResult, let url = URL(string: result.magnetLink) {
                            activityItem = ActivityItem(items: url)
                        }
                    }

                    ListRowButtonView("Open in WebTor", systemImage: "arrow.up.forward.app.fill") {
                        if let result = scrapingModel.selectedSearchResult {
                            navModel.runMagnetAction(action: .webtor, searchResult: result)
                        }
                    }
                }
            }
            .activitySheet($activityItem)
            .navigationTitle("Link actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        debridManager.realDebridDownloadUrl = ""

                        dismiss()
                    }
                }
            }
        }
    }
}

struct MagnetChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        MagnetChoiceView()
    }
}

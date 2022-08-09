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
                            guard let downloadUrl = URL(string: "outplayer://\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
                        }

                        ListRowButtonView("Play on VLC", systemImage: "arrow.up.forward.app.fill") {
                            guard let downloadUrl = URL(string: "vlc://\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
                        }

                        ListRowButtonView("Play on Infuse", systemImage: "arrow.up.forward.app.fill") {
                            guard let downloadUrl = URL(string: "infuse://x-callback-url/play?url=\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
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
                            showActivityView.toggle()
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
                            showActivityView.toggle()
                        }
                    }

                    ListRowButtonView("Open in WebTor", systemImage: "arrow.up.forward.app.fill") {
                        if let result = scrapingModel.selectedSearchResult,
                           let url = URL(string: "https://webtor.io/#/show?magnet=\(result.magnetLink)")
                        {
                            UIApplication.shared.open(url)
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

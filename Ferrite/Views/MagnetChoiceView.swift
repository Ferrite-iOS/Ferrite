//
//  MagnetChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import SwiftUI
import SwiftUIX

struct MagnetChoiceView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @State private var showLinkCopyAlert = false
    @State private var showMagnetCopyAlert = false

    var body: some View {
        NavView {
            Form {
                if !debridManager.realDebridDownloadUrl.isEmpty {
                    Section(header: "Real Debrid options") {
                        ListRowButtonView("Play on Outplayer", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.realDebridDownloadUrl, .outplayer)
                        }

                        ListRowButtonView("Play on VLC", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.realDebridDownloadUrl, .vlc)
                        }

                        ListRowButtonView("Play on Infuse", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.realDebridDownloadUrl, .infuse)
                        }

                        ListRowButtonView("Copy download URL", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = debridManager.realDebridDownloadUrl
                            showLinkCopyAlert.toggle()
                        }
                        .dynamicAlert(
                            isPresented: $showLinkCopyAlert ,
                            title: "Copied",
                            message: "Download link copied successfully",
                            buttons: [AlertButton("OK")]
                        )

                        ListRowButtonView("Share download URL", systemImage: "square.and.arrow.up.fill") {
                            if let url = URL(string: debridManager.realDebridDownloadUrl) {
                                navModel.activityItems = [url]
                                navModel.showLocalActivitySheet.toggle()
                            }
                        }
                    }
                }

                Section(header: "Magnet options") {
                    ListRowButtonView("Copy magnet", systemImage: "doc.on.doc.fill") {
                        UIPasteboard.general.string = navModel.selectedSearchResult?.magnetLink
                        showMagnetCopyAlert.toggle()
                    }
                    .dynamicAlert(
                        isPresented: $showMagnetCopyAlert,
                        title: "Copied",
                        message: "Magnet link copied successfully",
                        buttons: [AlertButton("OK")]
                    )

                    ListRowButtonView("Share magnet", systemImage: "square.and.arrow.up.fill") {
                        if let result = navModel.selectedSearchResult,
                           let magnetLink = result.magnetLink,
                           let url = URL(string: magnetLink)
                        {
                            navModel.activityItems = [url]
                            navModel.showLocalActivitySheet.toggle()
                        }
                    }

                    ListRowButtonView("Open in WebTor", systemImage: "arrow.up.forward.app.fill") {
                        navModel.runMagnetAction(magnetString: navModel.selectedSearchResult?.magnetLink, .webtor)
                    }
                }
            }
            .dynamicAccentColor(.primary)
            .sheet(isPresented: $navModel.showLocalActivitySheet) {
                if #available(iOS 16, *) {
                    AppActivityView(activityItems: navModel.activityItems)
                        .presentationDetents([.medium, .large])
                } else {
                    AppActivityView(activityItems: navModel.activityItems)
                }
            }
            .onDisappear {
                debridManager.realDebridDownloadUrl = ""
            }
            .navigationTitle("Link actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        debridManager.realDebridDownloadUrl = ""

                        presentationMode.wrappedValue.dismiss()
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

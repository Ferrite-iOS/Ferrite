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
                Section(header: "Now Playing") {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(navModel.selectedTitle)
                            .font(.callout)
                            .lineLimit(navModel.selectedBatchTitle.isEmpty ? .max : 1)

                        if !navModel.selectedBatchTitle.isEmpty {
                            Text(navModel.selectedBatchTitle)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }

                if !debridManager.downloadUrl.isEmpty {
                    Section(header: "Debrid options") {
                        ListRowButtonView("Play on Outplayer", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.downloadUrl, .outplayer)
                        }

                        ListRowButtonView("Play on VLC", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.downloadUrl, .vlc)
                        }

                        ListRowButtonView("Play on Infuse", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runDebridAction(urlString: debridManager.downloadUrl, .infuse)
                        }

                        ListRowButtonView("Copy download URL", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = debridManager.downloadUrl
                            showLinkCopyAlert.toggle()
                        }
                        .backport.alert(
                            isPresented: $showLinkCopyAlert,
                            title: "Copied",
                            message: "Download link copied successfully",
                            buttons: [AlertButton("OK")]
                        )

                        ListRowButtonView("Share download URL", systemImage: "square.and.arrow.up.fill") {
                            if let url = URL(string: debridManager.downloadUrl) {
                                navModel.activityItems = [url]
                                navModel.showLocalActivitySheet.toggle()
                            }
                        }
                    }
                }

                if !navModel.resultFromCloud {
                    Section(header: "Magnet options") {
                        ListRowButtonView("Copy magnet", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = navModel.selectedMagnetLink
                            showMagnetCopyAlert.toggle()
                        }
                        .backport.alert(
                            isPresented: $showMagnetCopyAlert,
                            title: "Copied",
                            message: "Magnet link copied successfully",
                            buttons: [AlertButton("OK")]
                        )

                        ListRowButtonView("Share magnet", systemImage: "square.and.arrow.up.fill") {
                            if let magnetLink = navModel.selectedMagnetLink,
                               let url = URL(string: magnetLink)
                            {
                                navModel.activityItems = [url]
                                navModel.showLocalActivitySheet.toggle()
                            }
                        }

                        ListRowButtonView("Open in WebTor", systemImage: "arrow.up.forward.app.fill") {
                            navModel.runMagnetAction(magnetString: navModel.selectedMagnetLink, .webtor)
                        }
                    }
                }
            }
            .backport.tint(.primary)
            .sheet(isPresented: $navModel.showLocalActivitySheet) {
                if #available(iOS 16, *) {
                    AppActivityView(activityItems: navModel.activityItems)
                        .presentationDetents([.medium, .large])
                } else {
                    AppActivityView(activityItems: navModel.activityItems)
                }
            }
            .onDisappear {
                debridManager.downloadUrl = ""
                navModel.selectedTitle = ""
                navModel.selectedBatchTitle = ""
                navModel.resultFromCloud = false
            }
            .navigationTitle("Link actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        debridManager.downloadUrl = ""
                        navModel.selectedTitle = ""
                        navModel.selectedBatchTitle = ""

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

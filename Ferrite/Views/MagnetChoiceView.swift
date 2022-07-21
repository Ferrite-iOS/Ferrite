//
//  MagnetChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import SwiftUI
import ActivityView

struct MagnetChoiceView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var debridManager: DebridManager

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @Binding var selectedResult: SearchResult?

    @State private var showActivityView = false
    @State private var activityItem: ActivityItem?

    var body: some View {
        NavView {
            Form {
                if realDebridEnabled, debridManager.realDebridHashes.contains(selectedResult?.magnetHash ?? "") {
                    Section("Real Debrid options") {
                        Button("Play on Outplayer") {
                            guard let downloadUrl = URL(string: "outplayer://\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
                        }

                        Button("Play on VLC") {
                            guard let downloadUrl = URL(string: "vlc://\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
                        }

                        Button("Play on Infuse") {
                            guard let downloadUrl = URL(string: "infuse://x-callback-url/play?url=\(debridManager.realDebridDownloadUrl)") else {
                                return
                            }

                            UIApplication.shared.open(downloadUrl)
                        }

                        Button("Copy download URL") {
                            UIPasteboard.general.string = debridManager.realDebridDownloadUrl
                        }

                        Button("Share download URL") {
                            guard let url = URL(string: debridManager.realDebridDownloadUrl) else {
                                return
                            }

                            activityItem = ActivityItem(items: url)
                            showActivityView.toggle()
                        }
                    }
                }

                Section("Magnet options") {
                    Button("Copy magnet") {
                        UIPasteboard.general.string = selectedResult?.magnetLink
                    }

                    Button("Share magnet") {
                        if let result = selectedResult, let url = URL(string: result.magnetLink) {
                            activityItem = ActivityItem(items: url)
                            showActivityView.toggle()
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
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MagnetChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        MagnetChoiceView(
            selectedResult:
                .constant(
                    SearchResult(
                        title: "",
                        source: "",
                        size: "",
                        magnetLink: "",
                        magnetHash: nil)
                )
        )
    }
}

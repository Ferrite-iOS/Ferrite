//
//  HistoryButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/9/22.
//

import SwiftUI

struct HistoryButtonView: View {
    @EnvironmentObject var logManager: LoggingManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var pluginManager: PluginManager

    let entry: HistoryEntry

    var body: some View {
        Button {
            navModel.selectedTitle = entry.name ?? ""
            navModel.selectedBatchTitle = entry.subName ?? ""

            if let url = entry.url {
                if url.starts(with: "https://") {
                    Task {
                        debridManager.downloadUrl = url
                        pluginManager.runDefaultAction(
                            urlString: url,
                            navModel: navModel
                        )

                        if navModel.currentChoiceSheet != .action {
                            debridManager.downloadUrl = ""
                        }
                    }
                } else {
                    pluginManager.runDefaultAction(
                        urlString: url,
                        navModel: navModel
                    )
                }
            } else {
                logManager.error(
                    "History: URL for name \(String(describing: entry.name)) is invalid",
                    description: "URL invalid. Cannot load this history entry. Please delete it."
                )
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Text(entry.name ?? "Unknown title")
                        .font(entry.subName == nil ? .body : .subheadline)
                        .lineLimit(entry.subName == nil ? 2 : 1)

                    if let subName = entry.subName {
                        Text(subName)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                }

                HStack {
                    Text(entry.source ?? "Unknown source")

                    Spacer()

                    Text("DEBRID")
                        .fontWeight(.bold)
                        .padding(3)
                        .background {
                            Group {
                                if let url = entry.url, url.starts(with: "https://") {
                                    Color.green
                                } else {
                                    Color.red
                                }
                            }
                            .cornerRadius(4)
                            .opacity(0.5)
                        }
                }
                .font(.caption)
            }
            .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
        }
        .tint(.primary)
        .disableInteraction(navModel.currentChoiceSheet != nil)
    }

    func getTagColor() -> Color {
        if let url = entry.url, url.starts(with: "https://") {
            return Color.green
        } else {
            return Color.red
        }
    }
}

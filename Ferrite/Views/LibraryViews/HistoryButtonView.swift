//
//  HistoryButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/9/22.
//

import SwiftUI

struct HistoryButtonView: View {
    @EnvironmentObject var toastModel: ToastViewModel
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    let entry: HistoryEntry

    var body: some View {
        Button {
            if let url = entry.url {
                if url.starts(with: "https://") {
                    Task {
                        debridManager.realDebridDownloadUrl = url
                        navModel.runDebridAction(urlString: url)

                        if navModel.currentChoiceSheet != .magnet {
                            debridManager.realDebridDownloadUrl = ""
                        }
                    }
                } else {
                    navModel.runMagnetAction(magnetString: url)
                }
            } else {
                toastModel.updateToastDescription("URL invalid. Cannot load this history entry. Please delete it.")
            }
        } label: {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name ?? "Unknown title")
                        .font(entry.subName == nil ? .body : .subheadline)

                    if let subName = entry.subName {
                        Text(subName)
                            .foregroundColor(.gray)
                            .font(.subheadline)
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
            .lineLimit(1)
            .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
        }
        .backport.tint(.white)
        .disableInteraction(navModel.currentChoiceSheet != nil)
    }
}

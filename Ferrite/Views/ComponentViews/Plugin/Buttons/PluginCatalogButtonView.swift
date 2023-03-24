//
//  SourceCatalogButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct PluginCatalogButtonView<PJ: PluginJson>: View {
    @EnvironmentObject var pluginManager: PluginManager

    let availablePlugin: PJ
    let needsUpdate: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(availablePlugin.name)
                        Text("v\(availablePlugin.version)")
                            .foregroundColor(.secondary)
                    }

                    Group {
                        Text("by \(availablePlugin.author ?? "No author")")

                        Text(availablePlugin.listName.map { "from \($0)" } ?? "an unknown list")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }

                if let tags = availablePlugin.getTags(), !tags.isEmpty {
                    PluginTagsView(tags: tags)
                }
            }

            Spacer()

            Button(needsUpdate ? "UPDATE" : "INSTALL") {
                Task {
                    if let availableSource = availablePlugin as? SourceJson {
                        await pluginManager.installSource(sourceJson: availableSource, doUpsert: needsUpdate)
                    } else if let availableAction = availablePlugin as? ActionJson {
                        await pluginManager.installAction(actionJson: availableAction, doUpsert: needsUpdate)
                    } else {
                        return
                    }
                }
            }
            .font(
                .footnote
                    .weight(.bold)
            )
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(.tertiarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 2)
    }
}

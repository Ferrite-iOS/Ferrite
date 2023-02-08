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
    let doUpsert: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(availablePlugin.name)
                        Text("v\(availablePlugin.version)")
                            .foregroundColor(.secondary)
                    }

                    Text("by \(availablePlugin.author ?? "No author")")
                        .foregroundColor(.secondary)
                }

                if let tags = availablePlugin.getTags(), !tags.isEmpty {
                    PluginTagsView(tags: tags)
                }
            }

            Spacer()

            Button("Install") {
                Task {
                    if let availableSource = availablePlugin as? SourceJson {
                        await pluginManager.installSource(sourceJson: availableSource, doUpsert: doUpsert)
                    } else if let availableAction = availablePlugin as? ActionJson {
                        await pluginManager.installAction(actionJson: availableAction, doUpsert: doUpsert)
                    } else {
                        return
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

//
//  PluginInfoMetaView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/2/23.
//

import SwiftUI

struct PluginInfoMetaView<P: Plugin>: View {
    @ObservedObject var selectedPlugin: P

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    var body: some View {
        Section(header: InlineHeader("Metadata")) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(selectedPlugin.name)

                        Text("v\(selectedPlugin.version)")
                            .foregroundColor(.secondary)
                    }

                    Text("by \(selectedPlugin.author)")
                        .foregroundColor(.secondary)

                    Group {
                        Text("ID: \(selectedPlugin.id)")

                        if let pluginList = pluginLists.first(where: { $0.id == selectedPlugin.listId })
                        {
                            Text("List: \(pluginList.name)")
                            Text("List ID: \(pluginList.id.uuidString)")
                        } else {
                            Text("No plugin list found. This source should be removed.")
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.caption)
                }

                let tags = selectedPlugin.getTags()
                if !tags.isEmpty {
                    PluginTagsView(tags: tags)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

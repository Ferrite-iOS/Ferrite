//
//  PluginInfoView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct PluginInfoView<P: Plugin>: View {
    @Environment(\.presentationMode) var presentationMode

    @Binding var selectedPlugin: P?

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    var body: some View {
        NavView {
            List {
                if let selectedPlugin {
                    Section(header: InlineHeader("Info")) {
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

                            if let tags = selectedPlugin.getTags(), !tags.isEmpty {
                                PluginTagsView(tags: tags)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if let selectedSource = selectedPlugin as? Source {
                        SourceSettingsView(selectedSource: selectedSource)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onDisappear {
                PersistenceController.shared.save()
            }
            .navigationTitle("Plugin Options")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

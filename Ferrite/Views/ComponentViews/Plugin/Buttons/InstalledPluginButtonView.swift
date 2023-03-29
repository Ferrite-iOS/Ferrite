//
//  InstalledSourceButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct InstalledPluginButtonView<P: Plugin>: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @ObservedObject var installedPlugin: P

    @Binding var showPluginOptions: Bool
    @Binding var selectedPlugin: P?

    var body: some View {
        Toggle(isOn: Binding<Bool>(
            get: { installedPlugin.enabled },
            set: {
                installedPlugin.enabled = $0
                PersistenceController.shared.save()
            }
        )) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(installedPlugin.name)
                        Text("v\(installedPlugin.version)")
                            .foregroundColor(.secondary)
                    }

                    Text("by \(installedPlugin.author)")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let tags = installedPlugin.getTags(), !tags.isEmpty {
                    PluginTagsView(tags: tags)
                }
            }
            .padding(.vertical, 2)
        }
        .contextMenu {
            Button {
                selectedPlugin = installedPlugin
                showPluginOptions.toggle()
            } label: {
                Text("Options")
                Image(systemName: "gear")
            }

            Button(role: .destructive) {
                PersistenceController.shared.delete(installedPlugin, context: backgroundContext)
            } label: {
                Text("Remove")
                Image(systemName: "trash")
            }
        }
    }
}

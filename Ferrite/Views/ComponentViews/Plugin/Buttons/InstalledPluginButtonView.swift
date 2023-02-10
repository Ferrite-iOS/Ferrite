//
//  InstalledSourceButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct InstalledPluginButtonView<P: Plugin>: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel

    @ObservedObject var installedPlugin: P

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
                    HStack {
                        Text(installedPlugin.name)
                        Text("v\(installedPlugin.version)")
                            .foregroundColor(.secondary)
                    }

                    Text("by \(installedPlugin.author)")
                        .foregroundColor(.secondary)
                }

                if let tags = installedPlugin.getTags(), !tags.isEmpty {
                    PluginTagsView(tags: tags)
                }
            }
            .padding(.vertical, 2)
        }
        .contextMenu {
            if let installedSource = installedPlugin as? Source {
                Button {
                    navModel.selectedSource = installedSource
                    navModel.showSourceSettings.toggle()
                } label: {
                    Text("Settings")
                    Image(systemName: "gear")
                }
            }

            if #available(iOS 15.0, *) {
                Button(role: .destructive) {
                    PersistenceController.shared.delete(installedPlugin, context: backgroundContext)
                    NotificationCenter.default.post(name: .didDeletePlugin, object: nil)
                } label: {
                    Text("Remove")
                    Image(systemName: "trash")
                }
            } else {
                Button {
                    PersistenceController.shared.delete(installedPlugin, context: backgroundContext)
                    NotificationCenter.default.post(name: .didDeletePlugin, object: nil)
                } label: {
                    Text("Remove")
                    Image(systemName: "trash")
                }
            }
        }
    }
}

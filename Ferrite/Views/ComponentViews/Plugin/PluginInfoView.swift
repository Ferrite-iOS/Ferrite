//
//  PluginInfoView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct PluginInfoView<P: Plugin>: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedPlugin: P?

    var body: some View {
        NavView {
            List {
                if let selectedPlugin {
                    PluginInfoMetaView(selectedPlugin: selectedPlugin)

                    if selectedPlugin.about != nil || selectedPlugin.website != nil {
                        PluginInfoAboutView(selectedPlugin: selectedPlugin)
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
                        dismiss()
                    }
                }
            }
        }
    }
}

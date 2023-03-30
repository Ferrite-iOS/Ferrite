//
//  DefaultActionsPickerViews.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/11/22.
//

import SwiftUI

struct DefaultActionPickerView: View {
    @EnvironmentObject var logManager: LoggingManager

    let actionRequirement: ActionRequirement

    @Binding var defaultAction: DefaultAction

    @FetchRequest(
        entity: Action.entity(),
        sortDescriptors: []
    ) var actions: FetchedResults<Action>

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    var kodiServers: FetchedResults<KodiServer>

    var body: some View {
        List {
            Picker("", selection: $defaultAction) {
                Text("Let me choose").tag(DefaultAction.none)
                Text("Share link").tag(DefaultAction.share)

                if actionRequirement == .debrid, !kodiServers.isEmpty {
                    Text("Open in Kodi").tag(DefaultAction.kodi)
                }

                ForEach(actions.filter { $0.requires.contains(actionRequirement.rawValue) }, id: \.id) { action in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(action.name)

                        Group {
                            if let associatedPluginList = pluginLists.first(where: { $0.id == action.listId }) {
                                Text("List: \(associatedPluginList.name)")

                                Text(associatedPluginList.id.uuidString)
                                    .font(.caption)
                            } else {
                                Text("No plugin list found")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                    .tag(DefaultAction.custom(name: action.name, listId: action.listId?.uuidString ?? ""))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .listStyle(.insetGrouped)
        .inlinedList(inset: -20)
        .navigationTitle("Default \(actionRequirement == .debrid ? "Debrid" : "Magnet") Action")
        .navigationBarTitleDisplayMode(.inline)
    }
}

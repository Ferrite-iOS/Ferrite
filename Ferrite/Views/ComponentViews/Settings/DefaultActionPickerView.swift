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

    @FetchRequest(
        entity: KodiServer.entity(),
        sortDescriptors: []
    ) var kodiServers: FetchedResults<KodiServer>

    var body: some View {
        List {
            DefaultChoiceButton(defaultAction: $defaultAction, selectedOption: .none)
            DefaultChoiceButton(defaultAction: $defaultAction, selectedOption: .share)

            if actionRequirement == .debrid && !kodiServers.isEmpty {
                DefaultChoiceButton(defaultAction: $defaultAction, selectedOption: .kodi)
            }

            // Handle custom here
            ForEach(actions.filter { $0.requires.contains(actionRequirement.rawValue) }, id: \.id) { action in
                Button {
                    if let actionListId = action.listId?.uuidString {
                        defaultAction = .custom(name: action.name, listId: actionListId)
                    } else {
                        logManager.error(
                            "Default action: This action doesn't have a corresponding plugin list! Please uninstall the action"
                        )
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(action.name)

                            Group {
                                if let pluginList = pluginLists.first(where: { $0.id == action.listId }) {
                                    Text("List: \(pluginList.name)")

                                    Text(pluginList.id.uuidString)
                                        .font(.caption)
                                } else {
                                    Text("No plugin list found")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        Spacer()

                        if
                            case let .custom(name, listId) = defaultAction,
                            action.listId?.uuidString == listId,
                            action.name == name
                        {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .backport.tint(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .inlinedList(inset: -20)
        .navigationTitle("Default \(actionRequirement == .debrid ? "Debrid" : "Magnet") Action")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DefaultChoiceButton: View {
    @Binding var defaultAction: DefaultAction
    let selectedOption: DefaultAction

    var body: some View {
        Button {
            defaultAction = selectedOption
        } label: {
            HStack {
                Text(fetchButtonName())
                Spacer()

                if defaultAction == selectedOption {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .backport.tint(.primary)
    }

    func fetchButtonName() -> String {
        switch selectedOption {
        case .none:
            return "Let me choose"
        case .share:
            return "Share link"
        case .kodi:
            return "Open in Kodi"
        case .custom(_, _):
            // This should not be called
            return "Custom button"
        }
    }
}

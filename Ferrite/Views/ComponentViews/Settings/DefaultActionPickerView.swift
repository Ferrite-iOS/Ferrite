//
//  DefaultActionsPickerViews.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/11/22.
//

import SwiftUI

struct DefaultActionPickerView: View {
    @EnvironmentObject var toastModel: ToastViewModel

    let actionRequirement: ActionRequirement
    @Binding var defaultActionName: String?
    @Binding var defaultActionList: String?

    @FetchRequest(
        entity: Action.entity(),
        sortDescriptors: []
    ) var actions: FetchedResults<Action>

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    var body: some View {
        List {
            UserChoiceButton(
                defaultActionName: $defaultActionName,
                defaultActionList: $defaultActionList,
                pluginLists: pluginLists
            )

            ForEach(actions.filter { $0.requires.contains(actionRequirement.rawValue) }, id: \.id) { action in
                Button {
                    if let actionListId = action.listId?.uuidString {
                        defaultActionName = action.name
                        defaultActionList = actionListId
                    } else {
                        toastModel.updateToastDescription(
                            "Default action error: This action doesn't have a corresponding plugin list! Please uninstall the action"
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
                            let defaultActionList,
                            action.listId?.uuidString == defaultActionList,
                            action.name == defaultActionName
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
        .navigationTitle("Default \(actionRequirement == .debrid ? "debrid" : "magnet") action")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UserChoiceButton: View {
    @Binding var defaultActionName: String?
    @Binding var defaultActionList: String?
    var pluginLists: FetchedResults<PluginList>

    var body: some View {
        Button {
            defaultActionName = nil
            defaultActionList = nil
        } label: {
            HStack {
                Text("Let me choose")
                Spacer()

                // Force "Let me choose" if the name OR list ID is nil
                // Prevents any mismatches
                if defaultActionName == nil || pluginLists.contains(where: { $0.id.uuidString == defaultActionList }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .backport.tint(.primary)
    }
}

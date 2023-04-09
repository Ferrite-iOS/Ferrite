//
//  PluginsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//

import SwiftUI

struct PluginsView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var navModel: NavigationViewModel

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var installedSources: FetchedResults<Source>

    @FetchRequest(
        entity: Action.entity(),
        sortDescriptors: []
    ) var installedActions: FetchedResults<Action>

    @State private var checkedForPlugins = false

    // Bound to the isSearching environment var
    @State private var isSearching = false
    @State private var searchText: String = ""

    var body: some View {
        NavView {
            ZStack {
                if checkedForPlugins {
                    switch navModel.pluginPickerSelection {
                    case .sources:
                        PluginAggregateView<Source, SourceJson>(
                            installedPlugins: installedSources,
                            searchText: $searchText
                        )
                    case .actions:
                        PluginAggregateView<Action, ActionJson>(
                            installedPlugins: installedActions,
                            searchText: $searchText
                        )
                    }
                }
            }
            .overlay {
                if !isSearching {
                    if checkedForPlugins {
                        switch navModel.pluginPickerSelection {
                        case .sources:
                            if installedSources.isEmpty, pluginManager.availableSources.isEmpty {
                                EmptyInstructionView(title: "No Sources", message: "Add a plugin list in Settings")
                            }
                        case .actions:
                            if installedActions.isEmpty, pluginManager.availableActions.isEmpty {
                                EmptyInstructionView(title: "No Actions", message: "Add a plugin list in Settings")
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            .task {
                await pluginManager.fetchPluginsFromUrl()
                checkedForPlugins = true
            }
            .onDisappear {
                checkedForPlugins = false
            }
            .navigationTitle("Plugins")
            .expandedSearchable(
                text: $searchText,
                scopeBarContent: {
                    PluginPickerView()
                }
            )
            .autocorrectionDisabled(!autocorrectSearch)
            .esAutocapitalization(autocorrectSearch ? .sentences : .none)
        }
    }
}

struct PluginsView_Previews: PreviewProvider {
    static var previews: some View {
        PluginsView()
    }
}

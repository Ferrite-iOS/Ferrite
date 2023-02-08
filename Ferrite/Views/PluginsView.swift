//
//  PluginsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 1/11/23.
//

import SwiftUI
import SwiftUIX

struct PluginsView: View {
    enum PluginPickerSegment {
        case sources
        case actions
    }

    @EnvironmentObject var pluginManager: PluginManager

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    @FetchRequest(
        entity: Action.entity(),
        sortDescriptors: []
    ) var actions: FetchedResults<Action>

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @State private var selectedSegment: PluginPickerSegment = .sources
    @State private var checkedForPlugins = false

    @State private var isEditingSearch = false
    @State private var isSearching = false
    @State private var searchText: String = ""

    @State private var viewTask: Task<Void, Never>?

    var body: some View {
        NavView {
            VStack {
                Picker("Segments", selection: $selectedSegment) {
                    Text("Sources").tag(PluginPickerSegment.sources)
                    Text("Actions").tag(PluginPickerSegment.actions)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 5)

                if checkedForPlugins {
                    switch selectedSegment {
                    case .sources:
                        PluginListView<Source, SourceJson>(searchText: $searchText)
                    case .actions:
                        PluginListView<Action, ActionJson>(searchText: $searchText)
                    }
                }

                Spacer()
            }
            .overlay {
                if checkedForPlugins {
                    switch selectedSegment {
                    case .sources:
                        if sources.isEmpty && pluginManager.availableSources.isEmpty {
                            EmptyInstructionView(title: "No Sources", message: "Add a plugin list in Settings")
                        }
                    case .actions:
                        if actions.isEmpty && pluginManager.availableActions.isEmpty {
                            EmptyInstructionView(title: "No Actions", message: "Add a plugin list in Settings")
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                viewTask = Task {
                    await pluginManager.fetchPluginsFromUrl()
                    checkedForPlugins = true
                }
            }
            .onDisappear {
                viewTask?.cancel()
                checkedForPlugins = false
            }
            .navigationTitle("Plugins")
            .navigationSearchBar {
                SearchBar("Search", text: $searchText, isEditing: $isEditingSearch, onCommit: {
                    isSearching = true
                })
                .showsCancelButton(isEditingSearch || isSearching)
                .onCancel {
                    searchText = ""
                    isSearching = false
                }
            }
            .introspectSearchController { searchController in
                searchController.searchBar.autocorrectionType = autocorrectSearch ? .default : .no
                searchController.searchBar.autocapitalizationType = autocorrectSearch ? .sentences : .none
            }
        }
    }
}

struct PluginsView_Previews: PreviewProvider {
    static var previews: some View {
        PluginsView()
    }
}

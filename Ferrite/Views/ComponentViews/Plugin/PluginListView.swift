//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct PluginListView<P: Plugin, PJ: PluginJson>: View {
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @Binding var searchText: String

    @State private var isEditingSearch = false
    @State private var isSearching = false

    @State private var filteredUpdatedPlugins: [PJ] = []
    @State private var filteredAvailablePlugins: [PJ] = []
    @State private var sourcePredicate: NSPredicate?

    var body: some View {
        DynamicFetchRequest(predicate: sourcePredicate) { (installedPlugins: FetchedResults<P>) in
            List {
                if !filteredUpdatedPlugins.isEmpty {
                    Section(header: InlineHeader("Updates")) {
                        ForEach(filteredUpdatedPlugins, id: \.self) { (updatedPlugin: PJ) in
                            PluginCatalogButtonView(availablePlugin: updatedPlugin, doUpsert: true)
                        }
                    }
                }

                if !installedPlugins.isEmpty {
                    Section(header: InlineHeader("Installed")) {
                        ForEach(installedPlugins, id: \.self) { source in
                            InstalledPluginButtonView(installedPlugin: source)
                        }
                    }
                }

                if !filteredAvailablePlugins.isEmpty {
                    Section(header: InlineHeader("Catalog")) {
                        ForEach(filteredAvailablePlugins, id: \.self) { availablePlugin in
                            if !installedPlugins.contains(where: {
                                availablePlugin.name == $0.name &&
                                availablePlugin.listId == $0.listId &&
                                availablePlugin.author == $0.author
                            }) {
                                PluginCatalogButtonView(availablePlugin: availablePlugin, doUpsert: false)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .sheet(isPresented: $navModel.showSourceSettings) {
                if String(describing: P.self) == "Source" {
                    SourceSettingsView()
                        .environmentObject(navModel)
                }
            }
            .backport.onAppear {
                filteredAvailablePlugins = pluginManager.fetchFilteredPlugins(installedPlugins: installedPlugins, searchText: searchText)
                filteredUpdatedPlugins = pluginManager.fetchUpdatedPlugins(installedPlugins: installedPlugins, searchText: searchText)
            }
            .onChange(of: searchText) { _ in
                sourcePredicate = searchText.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            }
            .onReceive(installedPlugins.publisher.count()) { _ in
                filteredAvailablePlugins = pluginManager.fetchFilteredPlugins(installedPlugins: installedPlugins, searchText: searchText)
                filteredUpdatedPlugins = pluginManager.fetchUpdatedPlugins(installedPlugins: installedPlugins, searchText: searchText)
            }
        }
    }
}

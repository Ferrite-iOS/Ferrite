//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//
import SwiftUI

struct PluginAggregateView<P: Plugin, PJ: PluginJson>: View {
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @Binding var searchText: String
    @Binding var pluginsEmpty: Bool

    @State private var isEditingSearch = false
    @State private var isSearching = false

    @State private var sourcePredicate: NSPredicate?

    var body: some View {
        DynamicFetchRequest(predicate: sourcePredicate) { (installedPlugins: FetchedResults<P>) in
            List {
                if
                    let filteredUpdatedPlugins = pluginManager.fetchUpdatedPlugins(
                        forType: PJ.self,
                        installedPlugins: installedPlugins,
                        searchText: searchText
                    ),
                    !filteredUpdatedPlugins.isEmpty
                {
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

                if
                    let filteredAvailablePlugins = pluginManager.fetchFilteredPlugins(
                        forType: PJ.self,
                        installedPlugins: installedPlugins,
                        searchText: searchText
                    ),
                    !filteredAvailablePlugins.isEmpty
                {
                    Section(header: InlineHeader("Catalog")) {
                        ForEach(filteredAvailablePlugins, id: \.self) { availablePlugin in
                            PluginCatalogButtonView(availablePlugin: availablePlugin, doUpsert: false)
                        }
                    }
                }
            }
            .inlinedList(inset: 0)
            .listStyle(.insetGrouped)
            .sheet(isPresented: $navModel.showSourceSettings) {
                if String(describing: P.self) == "Source" {
                    SourceSettingsView()
                        .environmentObject(navModel)
                }
            }
            .backport.onAppear {
                pluginsEmpty = installedPlugins.isEmpty
            }
            .onChange(of: searchText) { _ in
                sourcePredicate = searchText.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            }
            .onChange(of: installedPlugins.count) { newCount in
                pluginsEmpty = newCount == 0
            }
            .id(UUID())
        }
    }
}

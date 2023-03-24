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

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @Binding var searchText: String
    @Binding var pluginsEmpty: Bool

    @State private var isEditingSearch = false
    @State private var isSearching = false

    @State private var sourcePredicate: NSPredicate?

    @State private var showPluginOptions = false
    @State private var selectedPlugin: P?

    var body: some View {
        ZStack {
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
                                PluginCatalogButtonView(availablePlugin: updatedPlugin, needsUpdate: true)
                            }
                        }
                    }

                    if !installedPlugins.isEmpty {
                        Section(header: InlineHeader("Installed")) {
                            ForEach(installedPlugins, id: \.self) { installedPlugin in
                                InstalledPluginButtonView(
                                    installedPlugin: installedPlugin,
                                    showPluginOptions: $showPluginOptions,
                                    selectedPlugin: $selectedPlugin
                                )
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
                                PluginCatalogButtonView(availablePlugin: availablePlugin, needsUpdate: false)
                            }
                        }
                    }
                }
                .inlinedList(inset: 0)
                .listStyle(.insetGrouped)
                .backport.onAppear {
                    pluginsEmpty = installedPlugins.isEmpty
                }
                .onChange(of: searchText) { _ in
                    sourcePredicate = searchText.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
                }
                .onChange(of: installedPlugins.count) { newCount in
                    pluginsEmpty = newCount == 0
                }
            }
        }
        .sheet(isPresented: $showPluginOptions) {
            PluginInfoView(selectedPlugin: $selectedPlugin)
        }
    }
}

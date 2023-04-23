//
//  SourceFilterView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/10/23.
//

import SwiftUI

// TODO: Make this use multiple selections
struct SourceFilterView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var navModel: NavigationViewModel

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    var body: some View {
        Menu {
            Button {
                pluginManager.filteredInstalledSources = []
            } label: {
                Text("All")

                if pluginManager.filteredInstalledSources.isEmpty {
                    Image(systemName: "checkmark")
                }
            }

            ForEach(sources, id: \.self) { source in
                let containsSource = pluginManager.filteredInstalledSources.contains(source)
                if source.enabled {
                    Button {
                        if containsSource {
                            pluginManager.filteredInstalledSources.remove(source)
                        } else {
                            pluginManager.filteredInstalledSources.insert(source)
                        }
                    } label: {
                        Text(source.name)

                        if containsSource {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterLabelView(
                name: pluginManager.filteredInstalledSources.first?.name,
                fallbackName: "Source",
                count: pluginManager.filteredInstalledSources.count
            )
        }
        .id(pluginManager.filteredInstalledSources)
        .onChange(of: pluginManager.filteredInstalledSources) { newSources in
            if newSources.isEmpty {
                navModel.enabledFilters.remove(.source)
            } else {
                navModel.enabledFilters.insert(.source)
            }
        }
        .onChange(of: navModel.enabledFilters) { newFilters in
            if newFilters.isEmpty {
                Task {
                    try? await Task.sleep(seconds: 0.25)
                    pluginManager.filteredInstalledSources = []
                }
            }
        }
    }
}

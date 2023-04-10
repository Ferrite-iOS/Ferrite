//
//  SearchFilterHeaderView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/13/23.
//

import SwiftUI

struct SearchFilterHeaderView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var pluginManager: PluginManager

    var sources: FetchedResults<Source>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // MARK: - Source filter picker

                // TODO: Make this use multiple selections
                Menu {
                    Picker("", selection: $pluginManager.filteredInstalledSources) {
                        Text("All").tag([] as [Source])

                        ForEach(sources, id: \.self) { source in
                            if source.enabled {
                                Text(source.name)
                                    .tag([source])
                            }
                        }
                    }
                } label: {
                    FilterLabelView(
                        name: pluginManager.filteredInstalledSources.first?.name ?? "Source"
                    )
                }
                .id(pluginManager.filteredInstalledSources)

                // MARK: - Selected debrid picker

                DebridPickerView {
                    FilterLabelView(name: debridManager.selectedDebridType?.toString() ?? "Debrid")
                }
                .id(debridManager.selectedDebridType)

                // MARK: - Cache status picker

                // TODO: Make this use multiple selections
                if !debridManager.enabledDebrids.isEmpty {
                    Menu {
                        Picker("", selection: $debridManager.filteredIAStatus) {
                            Text("All").tag([] as [IAStatus])

                            ForEach(IAStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag([status])
                            }
                        }
                    } label: {
                        FilterLabelView(
                            name: debridManager.filteredIAStatus.first?.rawValue ?? "Cache Status"
                        )
                    }
                    .id(debridManager.filteredIAStatus)
                }
            }
            .padding(.horizontal, verticalSizeClass == .compact ? 65 : 18)
        }
    }
}

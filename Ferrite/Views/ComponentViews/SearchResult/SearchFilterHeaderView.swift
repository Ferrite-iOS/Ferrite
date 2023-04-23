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
    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // MARK: - Current filters

                if !navModel.enabledFilters.isEmpty {
                    Menu {
                        Button("Clear filters", role: .destructive) {
                            navModel.enabledFilters = []
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .opacity(0.6)
                                .foregroundColor(.primary)

                            FilterAmountLabelView(amount: navModel.enabledFilters.count)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 2)
                        .font(
                            .caption
                                .weight(.medium)
                        )
                        .background(Capsule().foregroundColor(.init(uiColor: .secondarySystemFill)))
                    }

                    Divider()
                        .frame(width: 2, height: 20)
                }

                // MARK: - Source filter picker

                SourceFilterView()

                // MARK: - Selected debrid picker

                SelectedDebridFilterView {
                    FilterLabelView(
                        name: debridManager.selectedDebridType?.toString(),
                        fallbackName: "Debrid"
                    )
                }

                // MARK: - Cache status picker

                if !debridManager.enabledDebrids.isEmpty {
                    IAFilterView()
                }

                // MARK: - Sort filter picker

                SortFilterView()
            }
            .padding(.horizontal, verticalSizeClass == .compact ? 65 : 18)
            .animation(.easeInOut, value: navModel.enabledFilters)
        }
    }
}

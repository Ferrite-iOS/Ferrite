//
//  SearchFilterHeaderView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/13/23.
//

import SwiftUI

struct SearchFilterHeaderView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Menu {
                    Picker("", selection: $scrapingModel.filteredSource) {
                        Text("None").tag(nil as Source?)

                        ForEach(sources, id: \.self) { source in
                            if source.enabled {
                                Text(source.name)
                                    .tag(Source?.some(source))
                            }
                        }
                    }
                } label: {
                    FilterLabelView(name: scrapingModel.filteredSource?.name ?? "Source")
                }
                .id(scrapingModel.filteredSource)

                DebridPickerView {
                    FilterLabelView(name: debridManager.selectedDebridType?.toString() ?? "Debrid")
                }
                .id(debridManager.selectedDebridType)
            }
            .padding(.horizontal, verticalSizeClass == .compact ? 65 : 18)
        }
    }
}

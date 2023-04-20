//
//  SortFilterView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/14/23.
//

import SwiftUI

struct SortFilterView: View {
    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        Menu {
            Button {
                navModel.currentSortFilter = nil
                navModel.currentSortOrder = .forward
            } label: {
                HStack {
                    Text("None")

                    if navModel.currentSortFilter == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            ForEach(SortFilter.allCases, id: \.self) { sortFilter in
                Button {
                    navModel.currentSortFilter = sortFilter
                    navModel.currentSortOrder = navModel.currentSortOrder == .forward ? .reverse : .forward
                } label: {
                    HStack {
                        Text(sortFilter.rawValue)

                        if navModel.currentSortFilter == sortFilter {
                            Image(systemName: navModel.currentSortOrder == .forward ? "chevron.down" : "chevron.up")
                        }
                    }
                }
            }
        } label: {
            FilterLabelView(
                name: "Sort\(navModel.currentSortFilter.map { ": \($0.rawValue)" } ?? "")",
                count: navModel.currentSortFilter == nil ? 0 : 1
            )
        }
        .id(navModel.currentSortFilter)
        .onChange(of: navModel.currentSortFilter) { newFilter in
            navModel.currentSortOrder = .forward
            if newFilter == nil {
                navModel.enabledFilters.remove(.sort)
            } else {
                navModel.enabledFilters.insert(.sort)
            }
        }
        .onChange(of: navModel.enabledFilters) { newFilters in
            if newFilters.isEmpty {
                Task {
                    try? await Task.sleep(seconds: 0.25)
                    navModel.currentSortFilter = nil
                }
            }
        }
    }
}

struct SortFilterView_Previews: PreviewProvider {
    static var previews: some View {
        SortFilterView()
    }
}

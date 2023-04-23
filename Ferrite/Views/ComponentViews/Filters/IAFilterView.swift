//
//  IAFilterView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/10/23.
//

import SwiftUI

// TODO: Make this use multiple selections
struct IAFilterView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        Menu {
            Button {
                debridManager.filteredIAStatus = []
            } label: {
                Text("Any")

                if debridManager.filteredIAStatus.isEmpty {
                    Image(systemName: "checkmark")
                }
            }

            ForEach(IAStatus.allCases, id: \.self) { status in
                let containsIAStatus = debridManager.filteredIAStatus.contains(status)
                Button {
                    if containsIAStatus {
                        debridManager.filteredIAStatus.remove(status)
                    } else {
                        debridManager.filteredIAStatus.insert(status)
                    }
                } label: {
                    Text(status.rawValue)

                    if containsIAStatus {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            FilterLabelView(
                name: debridManager.filteredIAStatus.first?.rawValue,
                fallbackName: "Cache Status",
                count: debridManager.filteredIAStatus.count
            )
        }
        .id(debridManager.filteredIAStatus)
        .onChange(of: debridManager.filteredIAStatus) { newSources in
            if newSources.isEmpty {
                navModel.enabledFilters.remove(.IA)
            } else {
                navModel.enabledFilters.insert(.IA)
            }
        }
        .onChange(of: navModel.enabledFilters) { newFilters in
            if newFilters.isEmpty {
                Task {
                    try? await Task.sleep(seconds: 0.25)
                    debridManager.filteredIAStatus = []
                }
            }
        }
    }
}

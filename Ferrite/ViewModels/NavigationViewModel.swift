//
//  NavigationViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

enum ViewTab {
    case search
    case sources
    case settings
}

class NavigationViewModel: ObservableObject {
    // Used between SearchResultsView and MagnetChoiceView
    enum ChoiceSheetType: Identifiable {
        var id: Int {
            hashValue
        }

        case magnet
        case batch
    }

    @Published var currentChoiceSheet: ChoiceSheetType?

    @Published var selectedTab: ViewTab = .search
    @Published var showSearchProgress: Bool = false

    // Used between SourceListView and SourceSettingsView
    @Published var showSourceSettings: Bool = false
    @Published var selectedSource: Source?

    @Published var showSourceListEditor: Bool = false
    @Published var selectedSourceList: SourceList?
}

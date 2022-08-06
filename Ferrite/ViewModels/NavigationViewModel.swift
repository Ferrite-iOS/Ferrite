//
//  NavigationViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

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

    // Used between SourceListView and SourceSettingsView
    @Published var showSourceSettings: Bool = false
    @Published var selectedSource: Source?

    @Published var showSourceListEditor: Bool = false
    @Published var selectedSourceList: SourceList?
}

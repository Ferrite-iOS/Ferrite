//
//  NavigationViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

class NavigationViewModel: ObservableObject {
    enum ChoiceSheetType: Identifiable {
        var id: Int {
            hashValue
        }

        case magnet
        case batch
    }

    @Published var currentChoiceSheet: ChoiceSheetType?
}

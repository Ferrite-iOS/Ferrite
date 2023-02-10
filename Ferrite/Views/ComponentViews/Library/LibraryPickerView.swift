//
//  LibraryPickerView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/13/23.
//

import SwiftUI

struct LibraryPickerView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        HStack {
            Picker("Segments", selection: $navModel.libraryPickerSelection) {
                Text("Bookmarks").tag(NavigationViewModel.LibraryPickerSegment.bookmarks)
                Text("History").tag(NavigationViewModel.LibraryPickerSegment.history)

                if !debridManager.enabledDebrids.isEmpty {
                    Text("Cloud").tag(NavigationViewModel.LibraryPickerSegment.debridCloud)
                }
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, verticalSizeClass == .compact && UIDevice.current.hasNotch ? 65 : 18)
        .padding(.vertical, 5)
    }
}

//
//  PluginPickerView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/14/23.
//

import SwiftUI

struct PluginPickerView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @EnvironmentObject var navModel: NavigationViewModel

    @State private var textName = ""
    @State private var secondTextName = ""

    var body: some View {
        Picker("Segments", selection: $navModel.pluginPickerSelection) {
            Text("Sources").tag(NavigationViewModel.PluginPickerSegment.sources)
            Text("Actions").tag(NavigationViewModel.PluginPickerSegment.actions)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, verticalSizeClass == .compact && UIDevice.current.hasNotch ? 65 : 18)
        .padding(.vertical, 5)
    }
}

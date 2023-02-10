//
//  DebridChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/26/22.
//

import SwiftUI

struct DebridPickerView<Content: View>: View {
    @EnvironmentObject var debridManager: DebridManager

    @ViewBuilder var label: Content

    var body: some View {
        Menu {
            Picker("", selection: $debridManager.selectedDebridType) {
                Text("None")
                    .tag(nil as DebridType?)
                
                ForEach(DebridType.allCases, id: \.self) { (debridType: DebridType) in
                    if debridManager.enabledDebrids.contains(debridType) {
                        Text(debridType.toString())
                            .tag(DebridType?.some(debridType))
                    }
                }
            }
        } label: {
            label
        }
    }
}

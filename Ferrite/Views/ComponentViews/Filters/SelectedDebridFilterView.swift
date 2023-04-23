//
//  SelectedDebridFilterView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/10/23.
//

import SwiftUI

struct SelectedDebridFilterView<Content: View>: View {
    @EnvironmentObject var debridManager: DebridManager

    @ViewBuilder var label: Content

    var body: some View {
        Menu {
            Button {
                debridManager.selectedDebridType = nil
            } label: {
                Text("None")

                if debridManager.selectedDebridType == nil {
                    Image(systemName: "checkmark")
                }
            }

            ForEach(DebridType.allCases, id: \.self) { (debridType: DebridType) in
                if debridManager.enabledDebrids.contains(debridType) {
                    Button {
                        debridManager.selectedDebridType = debridType
                    } label: {
                        Text(debridType.toString())

                        if debridManager.selectedDebridType == debridType {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            label
        }
        .id(debridManager.selectedDebridType)
    }
}

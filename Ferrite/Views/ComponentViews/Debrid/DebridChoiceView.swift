//
//  DebridChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/26/22.
//

import SwiftUI

struct DebridChoiceView: View {
    @EnvironmentObject var debridManager: DebridManager

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
            Text(debridManager.selectedDebridType?.toString(abbreviated: true) ?? "Debrid")
        }
        .animation(.none)
    }
}

struct DebridChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        DebridChoiceView()
    }
}

//
//  GroupBoxStyle.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/21/22.
//

import SwiftUI

struct ErrorGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
            configuration.content
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

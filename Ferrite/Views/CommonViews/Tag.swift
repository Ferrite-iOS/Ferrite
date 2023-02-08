//
//  Tag.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/7/23.
//

import SwiftUI

struct Tag: View {
    let name: String
    let color: Color?
    var horizontalPadding: CGFloat = 7
    var verticalPadding: CGFloat = 4

    var body: some View {
        Text(name.capitalizingFirstLetter())
            .font(.caption)
            .opacity(0.8)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(color.map { $0 } ?? .tertiaryLabel)
                    .opacity(0.3)
            )
    }
}

//
//  FilterLabelView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/12/23.
//

import SwiftUI

struct FilterLabelView: View {
    var name: String

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .opacity(0.6)
                .foregroundColor(.primary)

            Image(systemName: "chevron.down")
                .foregroundColor(.tertiaryLabel)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .font(.caption, weight: .medium)
        .background(Capsule().foregroundColor(.secondarySystemFill))
    }
}

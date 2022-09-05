//
//  EmptyInstructionView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/5/22.
//

import SwiftUI

struct EmptyInstructionView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 25, weight: .semibold))

            Text(message)
                .padding(.horizontal, 50)
        }
        .multilineTextAlignment(.center)
        .foregroundColor(.secondaryLabel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

//
//  DisableInteraction.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/13/22.
//
//  Disables interaction on any view without applying the appearance
//

import SwiftUI

struct DisableInteraction: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if disabled {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(TapGesture())
                }
            }
    }
}

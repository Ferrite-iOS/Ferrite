//
//  DisabledAppearance.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/10/22.
//
//  Adds opacity transitions to the disabled modifier
//

import SwiftUI

struct DisabledAppearanceModifier: ViewModifier {
    let disabled: Bool
    let dimmedOpacity: Double?
    let animation: Animation?

    func body(content: Content) -> some View {
        content
            .disabled(disabled)
            .opacity(disabled ? dimmedOpacity.map { $0 } ?? 0.5 : 1)
            .animation(animation.map { $0 } ?? .none, value: disabled)
    }
}

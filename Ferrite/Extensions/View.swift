//
//  View.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/15/22.
//

import SwiftUI

extension View {
    // MARK: Modifiers

    func dynamicAccentColor(_ color: Color) -> some View {
        modifier(DynamicAccentColor(color: color))
    }
}

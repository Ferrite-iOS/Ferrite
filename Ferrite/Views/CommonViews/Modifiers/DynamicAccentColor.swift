//
//  DynamicAccentColor.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/15/22.
//
//  Wrapper that switches between tint and accentColor
//

import SwiftUI

struct DynamicAccentColor: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .tint(color)
        } else {
            content
                .accentColor(color)
        }
    }
}

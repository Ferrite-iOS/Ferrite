//
//  ViewDidAppearModifier.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/8/23.
//

import SwiftUI

struct ViewDidAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewDidAppearHandler(callback: callback))
    }
}

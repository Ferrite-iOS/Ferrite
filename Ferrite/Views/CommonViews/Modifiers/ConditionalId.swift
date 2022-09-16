//
//  ConditionalId.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/4/22.
//
//  Applies an ID below iOS 16
//  This is due to ID workarounds making iOS 16 apps crash
//

import SwiftUI

struct ConditionalId<ID: Hashable>: ViewModifier {
    let id: ID

    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
        } else {
            content
                .id(id)
        }
    }
}

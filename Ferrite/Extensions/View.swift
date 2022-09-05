//
//  View.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/15/22.
//

import SwiftUI
import Introspect

extension View {
    // MARK: Custom introspect functions

    func introspectCollectionView(customize: @escaping (UICollectionView) -> ()) -> some View {
        return inject(UIKitIntrospectionView(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
                    return nil
                }
                return Introspect.previousSibling(containing: UICollectionView.self, from: viewHost)
            },
            customize: customize
        ))
    }

    // MARK: Modifiers

    func dynamicAccentColor(_ color: Color) -> some View {
        modifier(DynamicAccentColor(color: color))
    }

    func conditionalId<ID: Hashable>(_ id: ID) -> some View {
        modifier(ConditionalId(id: id))
    }

    func inlinedList() -> some View {
        modifier(InlinedList())
    }
}

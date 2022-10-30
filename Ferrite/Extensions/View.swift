//
//  View.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/15/22.
//

import Introspect
import SwiftUI

extension View {
    // MARK: Custom introspect functions

    func introspectCollectionView(customize: @escaping (UICollectionView) -> Void) -> some View {
        inject(UIKitIntrospectionView(
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

    func conditionalContextMenu<InternalContent: View, ID: Hashable>(id: ID,
                                                                     @ViewBuilder _ internalContent: @escaping () -> InternalContent) -> some View
    {
        modifier(ConditionalContextMenu(internalContent, id: id))
    }

    func conditionalId<ID: Hashable>(_ id: ID) -> some View {
        modifier(ConditionalId(id: id))
    }

    func disabledAppearance(_ disabled: Bool, dimmedOpacity: Double? = nil, animation: Animation? = nil) -> some View {
        modifier(DisabledAppearance(disabled: disabled, dimmedOpacity: dimmedOpacity, animation: animation))
    }

    func disableInteraction(_ disabled: Bool) -> some View {
        modifier(DisableInteraction(disabled: disabled))
    }

    func inlinedList() -> some View {
        modifier(InlinedList())
    }
}

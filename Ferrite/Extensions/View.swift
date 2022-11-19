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

    func conditionalContextMenu(id: some Hashable,
                                @ViewBuilder _ internalContent: @escaping () -> some View) -> some View
    {
        modifier(ConditionalContextMenu(internalContent, id: id))
    }

    func conditionalId(_ id: some Hashable) -> some View {
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

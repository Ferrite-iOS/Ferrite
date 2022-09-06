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

    func dynamicAccentColor(_ color: Color) -> some View {
        modifier(DynamicAccentColor(color: color))
    }

    func conditionalId<ID: Hashable>(_ id: ID) -> some View {
        modifier(ConditionalId(id: id))
    }

    func disabledAppearance(_ disabled: Bool, dimmedOpacity: Double? = nil, animation: Animation? = nil) -> some View {
        modifier(DisabledAppearance(disabled: disabled, dimmedOpacity: dimmedOpacity, animation: animation))
    }

    func inlinedList() -> some View {
        modifier(InlinedList())
    }

    func conditionalContextMenu<InternalContent: View, ID: Hashable>(
        id: ID,
        @ViewBuilder _ internalContent: @escaping () -> InternalContent
    ) -> some View {
        modifier(ConditionalContextMenu(internalContent, id: id))
    }

    func dynamicActionSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        buttons: [AlertButton]) -> some View
    {
        modifier(DynamicActionSheet(isPresented: isPresented, title: title, message: message, buttons: buttons))
    }

    func dynamicAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        buttons: [AlertButton]) -> some View
    {
        modifier(DynamicAlert(isPresented: isPresented, title: title, message: message, buttons: buttons))
    }

    func disableInteraction(_ disabled: Bool) -> some View {
        modifier(DisableInteraction(disabled: disabled))
    }
}

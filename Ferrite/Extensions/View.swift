//
//  View.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/15/22.
//

import Introspect
import SwiftUI

extension View {
    // MARK: Modifiers

    func conditionalContextMenu(id: some Hashable,
                                @ViewBuilder _ internalContent: @escaping () -> some View) -> some View
    {
        modifier(ConditionalContextMenuModifier(internalContent, id: id))
    }

    func conditionalId(_ id: some Hashable) -> some View {
        modifier(ConditionalIdModifier(id: id))
    }

    func disabledAppearance(_ disabled: Bool, dimmedOpacity: Double? = nil, animation: Animation? = nil) -> some View {
        modifier(DisabledAppearanceModifier(disabled: disabled, dimmedOpacity: dimmedOpacity, animation: animation))
    }

    func disableInteraction(_ disabled: Bool) -> some View {
        modifier(DisableInteractionModifier(disabled: disabled))
    }

    func inlinedList(inset: CGFloat) -> some View {
        modifier(InlinedListModifier(inset: inset))
    }

    func viewDidAppear(_ callback: @escaping () -> Void) -> some View {
        modifier(ViewDidAppearModifier(callback: callback))
    }

    func customScopeBar(_ content: some View) -> some View {
        modifier(CustomScopeBarModifier(hostingContent: content))
    }

    func customScopeBar(_ content: @escaping () -> some View) -> some View {
        modifier(CustomScopeBarModifier(hostingContent: content()))
    }
}

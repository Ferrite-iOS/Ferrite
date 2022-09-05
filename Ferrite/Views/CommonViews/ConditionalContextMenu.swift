//
//  ConditionalContextMenu.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/3/22.
//
//  Used as a workaround for iOS 15 not updating context views with conditional variables
//  A stateful ID is required for the contextMenu to update itself.
//

import SwiftUI

struct ConditionalContextMenu<InternalContent: View, ID: Hashable>: ViewModifier {
    let internalContent: () -> InternalContent
    let id: ID

    init(@ViewBuilder _ internalContent: @escaping () -> InternalContent, id: ID) {
        self.internalContent = internalContent
        self.id = id
    }

    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .contextMenu {
                    internalContent()
                }
        } else {
            content
                .background {
                    Color.clear
                        .contextMenu {
                            internalContent()
                        }
                        .id(id)
                }
        }
    }
}

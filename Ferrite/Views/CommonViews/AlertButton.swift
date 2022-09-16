//
//  AlertButton.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/8/22.
//
//  Universal alert button for dynamic alert views
//

import SwiftUI

struct AlertButton: Identifiable {
    enum Role {
        case destructive
        case cancel
    }

    let id: UUID
    let label: String
    let action: () -> Void
    let role: Role?

    // Used for all buttons
    init(_ label: String, role: Role? = nil, action: @escaping () -> Void) {
        id = UUID()
        self.label = label
        self.action = action
        self.role = role
    }

    // Used for buttons with no action
    init(_ label: String = "Cancel", role: Role? = nil) {
        id = UUID()
        self.label = label
        action = {}
        self.role = role
    }

    func toActionButton() -> Alert.Button {
        if let role = role {
            switch role {
            case .cancel:
                return .cancel(Text(label))
            case .destructive:
                return .destructive(Text(label), action: action)
            }
        } else {
            return .default(Text(label), action: action)
        }
    }

    @available(iOS 15.0, *)
    @ViewBuilder
    func toButtonView() -> some View {
        Button(label, role: toButtonRole(role), action: action)
    }

    @available(iOS 15.0, *)
    func toButtonRole(_ role: Role?) -> ButtonRole? {
        if let role = role {
            switch role {
            case .destructive:
                return .destructive
            case .cancel:
                return .cancel
            }
        } else {
            return nil
        }
    }
}

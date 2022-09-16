//
//  DynamicAlert.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/8/22.
//
//  Switches between iOS 15 and 14 alert initalizers
//

import SwiftUI

struct DynamicAlert: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String?
    let buttons: [AlertButton]

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .alert(
                    title,
                    isPresented: $isPresented,
                    actions: {
                        ForEach(buttons) { button in
                            button.toButtonView()
                        }
                    },
                    message: {
                        if let message = message {
                            Text(message)
                        }
                    }
                )
        } else {
            content
                .alert(isPresented: $isPresented) {
                    if let primaryButton = buttons[safe: 0],
                       let secondaryButton = buttons[safe: 1]
                    {
                        return Alert(
                            title: Text(title),
                            message: message.map { Text($0) } ?? nil,
                            primaryButton: primaryButton.toActionButton(),
                            secondaryButton: secondaryButton.toActionButton()
                        )
                    } else {
                        return Alert(
                            title: Text(title),
                            message: message.map { Text($0) } ?? nil,
                            dismissButton: buttons[0].toActionButton()
                        )
                    }
                }
        }
    }
}

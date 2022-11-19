//
//  Backport.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/29/22.
//

import SwiftUI

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

extension View {
    var backport: Backport<Self> { Backport(self) }
}

extension Backport where Content: View {
    @ViewBuilder func alert(isPresented: Binding<Bool>, title: String, message: String?, buttons: [AlertButton]) -> some View {
        if #available(iOS 15, *) {
            content
                .alert(
                    title,
                    isPresented: isPresented,
                    actions: {
                        ForEach(buttons) { button in
                            button.toButtonView()
                        }
                    },
                    message: {
                        if let message {
                            Text(message)
                        }
                    }
                )
        } else {
            content
                .background {
                    Color.clear
                        .alert(isPresented: isPresented) {
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

    @ViewBuilder func confirmationDialog(isPresented: Binding<Bool>, title: String, message: String?, buttons: [AlertButton]) -> some View {
        if #available(iOS 15, *) {
            content
                .confirmationDialog(
                    title,
                    isPresented: isPresented,
                    titleVisibility: .visible
                ) {
                    ForEach(buttons) { button in
                        button.toButtonView()
                    }
                } message: {
                    if let message {
                        Text(message)
                    }
                }
        } else {
            content
                .actionSheet(isPresented: isPresented) {
                    ActionSheet(
                        title: Text(title),
                        message: message.map { Text($0) } ?? nil,
                        buttons: [buttons.map { $0.toActionButton() }, [.cancel()]].flatMap { $0 }
                    )
                }
        }
    }

    @ViewBuilder func tint(_ color: Color) -> some View {
        if #available(iOS 15, *) {
            content
                .tint(color)
        } else {
            content
                .accentColor(color)
        }
    }
}

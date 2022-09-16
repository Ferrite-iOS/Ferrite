//
//  DynamicActionSheet.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/8/22.
//
//  Switches between confirmationDialog and actionSheet
//

import SwiftUI

struct DynamicActionSheet: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String?
    let buttons: [AlertButton]

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .confirmationDialog(
                    title,
                    isPresented: $isPresented,
                    titleVisibility: .visible
                ) {
                    ForEach(buttons) { button in
                        button.toButtonView()
                    }
                } message: {
                    if let message = message {
                        Text(message)
                    }
                }
        } else {
            content
                .actionSheet(isPresented: $isPresented) {
                    ActionSheet(
                        title: Text(title),
                        message: message.map { Text($0) } ?? nil,
                        buttons: [buttons.map { $0.toActionButton() }, [.cancel()]].flatMap { $0 }
                    )
                }
        }
    }
}

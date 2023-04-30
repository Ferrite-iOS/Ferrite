//
//  HybridSecureField.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import SwiftUI

struct HybridSecureField: View {
    enum Field: Hashable {
        case plain
        case secure
    }

    @Binding var text: String
    var onCommit: () -> Void = {}

    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    private var isFieldDisabled: Bool = false

    init(text: Binding<String>, onCommit: (() -> Void)? = nil, showPassword: Bool = false) {
        self._text = text
        if let onCommit {
            self.onCommit = onCommit
        }
        self.showPassword = showPassword
    }

    var body: some View {
        HStack {
            Group {
                if showPassword {
                    TextField("Password", text: $text, onCommit: onCommit)
                        .focused($focusedField, equals: .plain)
                } else {
                    SecureField("Password", text: $text, onCommit: onCommit)
                        .focused($focusedField, equals: .secure)
                }
            }
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .disabledAppearance(isFieldDisabled)

            Button {
                showPassword.toggle()
                focusedField = showPassword ? .plain : .secure
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
    }
}

extension HybridSecureField {
    public func fieldDisabled(_ isFieldDisabled: Bool) -> Self {
        modifyViewProp({ $0.isFieldDisabled = isFieldDisabled })
    }
}

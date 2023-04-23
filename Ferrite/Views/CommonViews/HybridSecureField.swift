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
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    var body: some View {
        HStack {
            Group {
                if showPassword {
                    TextField("Password", text: $text)
                        .focused($focusedField, equals: .plain)
                } else {
                    SecureField("Password", text: $text)
                        .focused($focusedField, equals: .secure)
                }
            }
            .autocorrectionDisabled(true)
            .autocapitalization(.none)

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

//
//  HybridSecureField.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import SwiftUI

struct HybridSecureField: View {
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack {
            Group {
                if showPassword {
                    TextField("Password", text: $text)
                } else {
                    SecureField("Password", text: $text)
                }
            }
            .autocorrectionDisabled(true)
            .autocapitalization(.none)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
}

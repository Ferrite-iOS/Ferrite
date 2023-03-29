//
//  LoginWebView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import SwiftUI

struct LoginWebView: View {
    @Environment(\.dismiss) var dismiss
    var url: URL

    var body: some View {
        NavView {
            WebView(url: url)
                .navigationTitle("Sign in")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct LoginWebView_Previews: PreviewProvider {
    static var previews: some View {
        LoginWebView(url: URL(string: "https://google.com")!)
    }
}

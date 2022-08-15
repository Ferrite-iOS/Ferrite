//
//  LoginWebView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import SwiftUI

struct LoginWebView: View {
    @Environment(\.presentationMode) var presentationMode
    var url: URL

    var body: some View {
        NavView {
            WebView(url: url)
                .navigationTitle("Sign in")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
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

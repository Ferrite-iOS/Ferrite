//
//  SourceSettingsBaseUrlView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct SourceSettingsBaseUrlView: View {
    @ObservedObject var selectedSource: Source

    @State private var tempBaseUrl: String = ""
    var body: some View {
        Section(
            header: InlineHeader("Base URL"),
            footer: Text("Enter the base URL of your server.")
        ) {
            TextField("https://...", text: $tempBaseUrl, onEditingChanged: { isFocused in
                if !isFocused {
                    if tempBaseUrl.last == "/" {
                        selectedSource.baseUrl = String(tempBaseUrl.dropLast())
                    } else {
                        selectedSource.baseUrl = tempBaseUrl
                    }
                }
            })
            .keyboardType(.URL)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .onAppear {
                tempBaseUrl = selectedSource.baseUrl ?? ""
            }
        }
    }
}

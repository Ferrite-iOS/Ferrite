//
//  SourceSettingsBaseUrlView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct SourceSettingsBaseUrlView: View {
    @ObservedObject var selectedSource: Source

    @State private var tempSite: String = ""
    var body: some View {
        Section(
            header: InlineHeader("Base URL"),
            footer: Text("Enter the base URL of your server.")
        ) {
            TextField("https://...", text: $tempSite, onEditingChanged: { isFocused in
                if !isFocused {
                    if tempSite.last == "/" {
                        selectedSource.website = String(tempSite.dropLast())
                    } else {
                        selectedSource.website = tempSite
                    }
                }
            })
            .keyboardType(.URL)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .onAppear {
                tempSite = selectedSource.website ?? ""
            }
        }
    }
}

//
//  SettingsKodiView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import SwiftUI

struct SettingsKodiView: View {
    @AppStorage("ExternalServices.KodiUrl") var kodiUrl: String = ""
    @AppStorage("ExternalServices.KodiUsername") var kodiUsername: String = ""
    @AppStorage("ExternalServices.KodiPassword") var kodiPassword: String = ""

    @State private var showPassword = false

    var body: some View {
        NavView {
            List {
                Section(header: InlineHeader("Description")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kodi is an external application that is used to manage a local media library and playback.")

                        Link("Website", destination: URL(string: "https://kodi.tv")!)
                    }
                }

                Section(
                    header: InlineHeader("Base URL"),
                    footer: Text("Enter your Kodi server's http URL here including the port.")
                ) {
                    TextField("http://...", text: $kodiUrl, onEditingChanged: { isFocused in
                        if !isFocused && kodiUrl.last == "/" {
                            kodiUrl = String(kodiUrl.dropLast())
                        }
                    })
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                }

                Section(
                    header: InlineHeader("Credentials"),
                    footer: Text("Enter your kodi username and password here (if applicable)")
                ) {
                    TextField("Username", text: $kodiUsername)

                    HybridSecureField(text: $kodiPassword)
                }
            }
            .navigationTitle("Kodi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsKodiView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsKodiView()
    }
}

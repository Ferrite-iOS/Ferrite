//
//  SourceSettingsApiView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct SourceSettingsApiView: View {
    @ObservedObject var selectedSourceApi: SourceApi

    @State private var tempClientId: String = ""
    @State private var tempClientSecret: String = ""

    enum Field {
        case secure, plain
    }

    var body: some View {
        Section(
            header: InlineHeader("API credentials"),
            footer: Text("Grab the required API credentials from the website. A client secret can be an API token.")
        ) {
            if let clientId = selectedSourceApi.clientId, clientId.dynamic {
                TextField("Client ID", text: $tempClientId, onEditingChanged: { isFocused in
                    if !isFocused {
                        clientId.value = tempClientId
                        clientId.timeStamp = Date()
                    }
                })
                .autocorrectionDisabled(true)
                .autocapitalization(.none)
                .onAppear {
                    tempClientId = clientId.value ?? ""
                }
            }

            if let clientSecret = selectedSourceApi.clientSecret, clientSecret.dynamic {
                TextField("Token", text: $tempClientSecret, onEditingChanged: { isFocused in
                    if !isFocused {
                        clientSecret.value = tempClientSecret
                        clientSecret.timeStamp = Date()
                    }
                })
                .autocorrectionDisabled(true)
                .autocapitalization(.none)
                .onAppear {
                    tempClientSecret = clientSecret.value ?? ""
                }
            }
        }
    }
}

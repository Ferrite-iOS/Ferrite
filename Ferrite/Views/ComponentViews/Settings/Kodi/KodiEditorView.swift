//
//  KodiEditorView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/6/23.
//

import SwiftUI

struct KodiEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var logManager: LoggingManager

    @State private var loadedSelectedServer = false

    @State private var serverUrl: String = ""
    @State private var friendlyName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""

    @State private var showErrorAlert = false
    @State private var errorAlertText: String = ""

    var body: some View {
        NavView {
            Form {
                Group {
                    Section(
                        header: InlineHeader("URL"),
                        footer: Text("Must follow the format http(s)://<ip>:<port>")
                    ) {
                        TextField("Enter URL", text: $serverUrl)
                            .keyboardType(.URL)
                    }

                    Section(
                        header: InlineHeader("Friendly name"),
                        footer: Text("Defaults to the URL if not provided")
                    ) {
                        TextField("Friendly name", text: $friendlyName)
                    }

                    Section(
                        header: InlineHeader("Credentials"),
                        footer: Text("Only use for clients with authentication")
                    ) {
                        TextField("Username", text: $username)

                        HybridSecureField(text: $password)
                    }
                }
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .id(loadedSelectedServer)
            }
            .backport.onAppear {
                if let selectedKodiServer = navModel.selectedKodiServer {
                    serverUrl = selectedKodiServer.urlString
                    friendlyName = selectedKodiServer.name
                    username = selectedKodiServer.username ?? ""
                    password = selectedKodiServer.password ?? ""

                    loadedSelectedServer.toggle()
                }
            }
            .backport.alert(
                isPresented: $showErrorAlert,
                title: "Error",
                message: errorAlertText
            )
            .navigationTitle("Editing Kodi Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        do {
                            try pluginManager.kodi.addServer(
                                urlString: serverUrl,
                                friendlyName: friendlyName.isEmpty ? nil : friendlyName,
                                username: username.isEmpty ? nil : username,
                                password: password.isEmpty ? nil : password,
                                existingServer: navModel.selectedKodiServer
                            )

                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            logManager.error("Editing Kodi server: \(error)", showToast: false)
                            errorAlertText = error.localizedDescription
                            showErrorAlert.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct KodiEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KodiEditorView()
    }
}

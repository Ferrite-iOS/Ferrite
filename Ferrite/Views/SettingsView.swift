//
//  SettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var sourceManager: SourceManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false
    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    @State private var isProcessing = false

    var body: some View {
        NavView {
            Form {
                Section(header: "Debrid services") {
                    HStack {
                        Text("Real Debrid")
                        Spacer()
                        Button {
                            Task {
                                if realDebridEnabled {
                                    try? await debridManager.realDebrid.deleteTokens()
                                } else if !isProcessing {
                                    await debridManager.authenticateRd()
                                    isProcessing = true
                                }
                            }
                        } label: {
                            Text(realDebridEnabled ? "Logout" : (isProcessing ? "Processing" : "Login"))
                                .foregroundColor(realDebridEnabled ? .red : .blue)
                        }
                    }
                }

                Section(header: "Source management") {
                    NavigationLink("Source lists", destination: SettingsSourceListView())
                }

                Section(header: "Default actions") {
                    if realDebridEnabled {
                        NavigationLink(
                            destination: DebridActionPickerView(),
                            label: {
                                HStack {
                                    Text("Default debrid action")
                                    Spacer()
                                    Group {
                                        switch defaultDebridAction {
                                        case .none:
                                            Text("User choice")
                                        case .outplayer:
                                            Text("Outplayer")
                                        case .vlc:
                                            Text("VLC")
                                        case .infuse:
                                            Text("Infuse")
                                        case .shareDownload:
                                            Text("Share")
                                        }
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                        )
                    }

                    NavigationLink(
                        destination: MagnetActionPickerView(),
                        label: {
                            HStack {
                                Text("Default magnet action")
                                Spacer()
                                Group {
                                    switch defaultMagnetAction {
                                    case .none:
                                        Text("User choice")
                                    case .webtor:
                                        Text("Webtor")
                                    case .shareMagnet:
                                        Text("Share")
                                    }
                                }
                                .foregroundColor(.gray)
                            }
                        }
                    )
                }

                Section {
                    ListRowLinkView(text: "Report issues", link: "https://github.com/bdashore3/Ferrite/issues")

                    NavigationLink("About", destination: AboutView())
                }
            }
            .sheet(isPresented: $debridManager.showWebView) {
                LoginWebView(url: URL(string: debridManager.realDebridAuthUrl)!)
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

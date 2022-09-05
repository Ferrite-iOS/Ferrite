//
//  SettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI
import Introspect

struct SettingsView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var sourceManager: SourceManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Updates.AutomaticNotifs") var autoUpdateNotifs = true

    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    var body: some View {
        NavView {
            Form {
                Section(header: InlineHeader("Debrid Services")) {
                    HStack {
                        Text("Real Debrid")
                        Spacer()
                        Button {
                            Task {
                                if debridManager.realDebridEnabled {
                                    await debridManager.logoutRd()
                                } else if !debridManager.realDebridAuthProcessing {
                                    await debridManager.authenticateRd()
                                }
                            }
                        } label: {
                            Text(debridManager.realDebridEnabled ? "Logout" : (debridManager.realDebridAuthProcessing ? "Processing" : "Login"))
                                .foregroundColor(debridManager.realDebridEnabled ? .red : .blue)
                        }
                    }
                }

                Section(header: InlineHeader("Source management")) {
                    NavigationLink("Source lists", destination: SettingsSourceListView())
                }

                Section(header: InlineHeader("Default actions")) {
                    if debridManager.realDebridEnabled {
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

                Section(header: InlineHeader("Updates")) {
                    Toggle(isOn: $autoUpdateNotifs) {
                        Text("Show update alerts")
                    }
                    NavigationLink("Version history", destination: SettingsAppVersionView())
                }

                Section(header: InlineHeader("Information")) {
                    ListRowLinkView(text: "Donate", link: "https://ko-fi.com/kingbri")
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

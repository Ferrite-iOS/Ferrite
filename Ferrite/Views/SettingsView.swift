//
//  SettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import BetterSafariView
import Introspect
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var pluginManager: PluginManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @AppStorage("Updates.AutomaticNotifs") var autoUpdateNotifs = true

    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    var body: some View {
        NavView {
            Form {
                Section(header: InlineHeader("Debrid Services")) {
                    HStack {
                        Text("RealDebrid")
                        Spacer()
                        Button {
                            Task {
                                if debridManager.enabledDebrids.contains(.realDebrid) {
                                    await debridManager.logoutDebrid(debridType: .realDebrid)
                                } else if !debridManager.realDebridAuthProcessing {
                                    await debridManager.authenticateDebrid(debridType: .realDebrid)
                                }
                            }
                        } label: {
                            Text(debridManager.enabledDebrids.contains(.realDebrid) ? "Logout" : (debridManager.realDebridAuthProcessing ? "Processing" : "Login"))
                                .foregroundColor(debridManager.enabledDebrids.contains(.realDebrid) ? .red : .blue)
                        }
                    }

                    HStack {
                        Text("AllDebrid")
                        Spacer()
                        Button {
                            Task {
                                if debridManager.enabledDebrids.contains(.allDebrid) {
                                    await debridManager.logoutDebrid(debridType: .allDebrid)
                                } else if !debridManager.allDebridAuthProcessing {
                                    await debridManager.authenticateDebrid(debridType: .allDebrid)
                                }
                            }
                        } label: {
                            Text(debridManager.enabledDebrids.contains(.allDebrid) ? "Logout" : (debridManager.allDebridAuthProcessing ? "Processing" : "Login"))
                                .foregroundColor(debridManager.enabledDebrids.contains(.allDebrid) ? .red : .blue)
                        }
                    }

                    HStack {
                        Text("Premiumize")
                        Spacer()
                        Button {
                            Task {
                                if debridManager.enabledDebrids.contains(.premiumize) {
                                    await debridManager.logoutDebrid(debridType: .premiumize)
                                } else if !debridManager.premiumizeAuthProcessing {
                                    await debridManager.authenticateDebrid(debridType: .premiumize)
                                }
                            }
                        } label: {
                            Text(debridManager.enabledDebrids.contains(.premiumize) ? "Logout" : (debridManager.premiumizeAuthProcessing ? "Processing" : "Login"))
                                .foregroundColor(debridManager.enabledDebrids.contains(.premiumize) ? .red : .blue)
                        }
                    }
                }

                Section(header: Text("Behavior")) {
                    Toggle(isOn: $autocorrectSearch) {
                        Text("Autocorrect search")
                    }
                }

                Section(header: Text("Plugin management")) {
                    NavigationLink("Plugin lists", destination: SettingsPluginListView())
                }

                Section(header: Text("Default actions")) {
                    if debridManager.enabledDebrids.count > 0 {
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

                Section(header: Text("Backups")) {
                    NavigationLink(destination: BackupsView()) {
                        Text("Backups")
                    }
                }

                Section(header: Text("Updates")) {
                    Toggle(isOn: $autoUpdateNotifs) {
                        Text("Show update alerts")
                    }
                    NavigationLink("Version history", destination: SettingsAppVersionView())
                }

                Section(header: Text("Information")) {
                    ListRowLinkView(text: "Donate", link: "https://ko-fi.com/kingbri")
                    ListRowLinkView(text: "Report issues", link: "https://github.com/bdashore3/Ferrite/issues")
                    NavigationLink("About", destination: AboutView())
                }
            }
            .sheet(isPresented: $debridManager.showWebView) {
                LoginWebView(url: debridManager.authUrl ?? URL(string: "https://google.com")!)
            }
            .webAuthenticationSession(isPresented: $debridManager.showAuthSession) {
                WebAuthenticationSession(
                    url: debridManager.authUrl ?? URL(string: "https://google.com")!,
                    callbackURLScheme: "ferrite"
                ) { callbackURL, error in
                    Task {
                        await debridManager.handleCallback(url: callbackURL, error: error)
                    }
                }
                .prefersEphemeralWebBrowserSession(true)
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

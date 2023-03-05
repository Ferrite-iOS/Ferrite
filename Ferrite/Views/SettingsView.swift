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

    @AppStorage("ExternalServices.KodiUrl") var kodiUrl: String = ""

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true
    @AppStorage("Behavior.UsesRandomSearchText") var usesRandomSearchText = false

    @AppStorage("Updates.AutomaticNotifs") var autoUpdateNotifs = true

    @AppStorage("Actions.DefaultDebridName") var defaultDebridActionName: String?
    @AppStorage("Actions.DefaultDebridList") var defaultDebridActionList: String?

    @AppStorage("Actions.DefaultMagnetName") var defaultMagnetActionName: String?
    @AppStorage("Actions.DefaultMagnetList") var defaultMagnetActionList: String?

    var body: some View {
        NavView {
            Form {
                Section(header: InlineHeader("Debrid services")) {
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

                Section(header: InlineHeader("Playback services")) {
                    NavigationLink(destination: SettingsKodiView(), label: {
                        HStack {
                            Text("Kodi")
                            Spacer()
                            Text(kodiUrl.isEmpty ? "Disabled" : "Enabled")
                                .foregroundColor(.secondary)
                        }
                    })
                }

                Section(header: InlineHeader("Behavior")) {
                    Toggle(isOn: $autocorrectSearch) {
                        Text("Autocorrect search")
                    }

                    Toggle(isOn: $usesRandomSearchText) {
                        Text("Random searchbar text")
                    }
                }

                Section(header: InlineHeader("Plugin management")) {
                    NavigationLink("Plugin lists", destination: SettingsPluginListView())
                }

                Section(header: InlineHeader("Default actions")) {
                    if debridManager.enabledDebrids.count > 0 {
                        NavigationLink(
                            destination: DefaultActionPickerView(
                                actionRequirement: .debrid,
                                defaultActionName: $defaultDebridActionName,
                                defaultActionList: $defaultDebridActionList
                            ),
                            label: {
                                HStack {
                                    Text("Debrid action")
                                    Spacer()

                                    // TODO: Maybe make this check for nil list as well?
                                    Text(defaultDebridActionName.map { $0 } ?? "User choice")
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                    }

                    NavigationLink(
                        destination: DefaultActionPickerView(
                            actionRequirement: .magnet,
                            defaultActionName: $defaultMagnetActionName,
                            defaultActionList: $defaultMagnetActionList
                        ),
                        label: {
                            HStack {
                                Text("Magnet action")
                                Spacer()

                                // TODO: Maybe make this check for nil list as well?
                                Text(defaultMagnetActionName.map { $0 } ?? "User choice")
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                }

                Section(header: InlineHeader("Backups")) {
                    NavigationLink(destination: BackupsView()) {
                        Text("Backups")
                    }
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

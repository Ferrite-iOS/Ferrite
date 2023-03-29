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

    @FetchRequest(
        entity: KodiServer.entity(),
        sortDescriptors: []
    ) var kodiServers: FetchedResults<KodiServer>

    @AppStorage("ExternalServices.KodiUrl") var kodiUrl: String = ""

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true
    @AppStorage("Behavior.UsesRandomSearchText") var usesRandomSearchText = false

    @AppStorage("Updates.AutomaticNotifs") var autoUpdateNotifs = true

    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: CodableWrapper<DefaultAction> = .init(value: .none)
    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: CodableWrapper<DefaultAction> = .init(value: .none)

    @AppStorage("Debug.ShowErrorToasts") var showErrorToasts = true

    var body: some View {
        NavView {
            Form {
                Section(header: InlineHeader("Debrid services")) {
                    ForEach(DebridType.allCases, id: \.self) { debridType in
                        NavigationLink(
                            destination: SettingsDebridInfoView(
                                debridType: debridType
                            ), label: {
                                HStack {
                                    Text(debridType.toString())
                                    Spacer()
                                    Text(debridManager.enabledDebrids.contains(debridType) ? "Enabled" : "Disabled")
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                    }
                }

                Section(header: InlineHeader("Playback services")) {
                    NavigationLink(destination: SettingsKodiView(kodiServers: kodiServers), label: {
                        HStack {
                            Text("Kodi")
                            Spacer()
                            Text(kodiServers.isEmpty ? "Disabled" : "Enabled")
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
                                defaultAction: $defaultDebridAction.value
                            ),
                            label: {
                                HStack {
                                    Text("Debrid action")
                                    Spacer()

                                    Group {
                                        switch defaultDebridAction.value {
                                        case .none:
                                            Text("User choice")
                                        case .share:
                                            Text("Share")
                                        case .kodi:
                                            Text("Kodi")
                                        case let .custom(name, _):
                                            Text(name)
                                        }
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                        )
                    }

                    NavigationLink(
                        destination: DefaultActionPickerView(
                            actionRequirement: .magnet,
                            defaultAction: $defaultMagnetAction.value
                        ),
                        label: {
                            HStack {
                                Text("Magnet action")
                                Spacer()

                                Group {
                                    switch defaultMagnetAction.value {
                                    case .none:
                                        Text("User choice")
                                    case .share:
                                        Text("Share")
                                    case .kodi:
                                        Text("Kodi")
                                    case let .custom(name, _):
                                        Text(name)
                                    }
                                }
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

                Section(header: InlineHeader("Debug")) {
                    NavigationLink("Logs", destination: SettingsLogView())
                    Toggle("Show error alerts", isOn: $showErrorToasts)
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

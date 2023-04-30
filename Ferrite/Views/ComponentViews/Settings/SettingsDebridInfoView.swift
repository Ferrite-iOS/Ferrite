//
//  DebridInfoView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/5/23.
//

import SwiftUI

struct SettingsDebridInfoView: View {
    @EnvironmentObject var debridManager: DebridManager

    let debridType: DebridType

    @State private var apiKeyTempText: String = ""

    var body: some View {
        List {
            Section(header: InlineHeader("Description")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(debridType.toString()) is a debrid service that is used for unrestricting downloads and media playback. You must pay to access the service.")

                    Link("Website", destination: URL(string: debridType.website()) ?? URL(string: "https://kingbri.dev/ferrite")!)
                }
            }

            Section(
                header: InlineHeader("Login status"),
                footer: Text("A WebView will show up to prompt you for credentials")
            ) {
                Button {
                    Task {
                        if debridManager.enabledDebrids.contains(debridType) {
                            await debridManager.logoutDebrid(debridType: debridType)
                        } else if !debridManager.authProcessing(debridType) {
                            await debridManager.authenticateDebrid(debridType: debridType, apiKey: nil)
                        }

                        apiKeyTempText = await debridManager.getManualAuthKey(debridType) ?? ""
                    }
                } label: {
                    Text(
                        debridManager.enabledDebrids.contains(debridType)
                            ? "Logout"
                            : (debridManager.authProcessing(debridType) ? "Processing" : "Login")
                    )
                    .foregroundColor(debridManager.enabledDebrids.contains(debridType) ? .red : .blue)
                }
            }

            Section(
                header: InlineHeader("API key"),
                footer: Text("Add a permanent API key here. Only use this if web authentication does not work!")
            ) {
                HybridSecureField(
                    text: $apiKeyTempText,
                    onCommit: {
                        Task {
                            if !apiKeyTempText.isEmpty {
                                await debridManager.authenticateDebrid(debridType: debridType, apiKey: apiKeyTempText)
                                apiKeyTempText = await debridManager.getManualAuthKey(debridType) ?? ""
                            }
                        }
                    }
                )
                .fieldDisabled(debridManager.enabledDebrids.contains(debridType))
            }
            .onAppear {
                Task {
                    apiKeyTempText = await debridManager.getManualAuthKey(debridType) ?? ""
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(debridType.toString())
        .navigationBarTitleDisplayMode(.inline)
    }
}

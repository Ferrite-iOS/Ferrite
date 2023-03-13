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
                        } else if !debridManager.getAuthProcessingBool(debridType: debridType) {
                            await debridManager.authenticateDebrid(debridType: debridType)
                        }
                    }
                } label: {
                    Text(
                        debridManager.enabledDebrids.contains(debridType)
                            ? "Logout"
                            : (debridManager.getAuthProcessingBool(debridType: debridType) ? "Processing" : "Login")
                    )
                    .foregroundColor(debridManager.enabledDebrids.contains(debridType) ? .red : .blue)
                }
            }
        }
        .navigationTitle(debridType.toString())
        .navigationBarTitleDisplayMode(.inline)
    }
}

//
//  SettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var debridManager: DebridManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @State private var isProcessing = false

    var body: some View {
        NavView {
            Form {
                Section("Debrid services") {
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

                Section("Source management") {
                    NavigationLink("Source lists", destination: SettingsSourceListView())
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

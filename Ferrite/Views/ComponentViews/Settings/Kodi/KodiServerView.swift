//
//  KodiServerView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/11/23.
//

import SwiftUI

struct KodiServerView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var logManager: LoggingManager

    var server: KodiServer

    @State private var isActive = false
    @State private var pingInProgress = false

    var body: some View {
        HStack {
            Text(server.name)
            Spacer()

            if pingInProgress {
                ProgressView()
            } else {
                Circle()
                    .foregroundColor(isActive ? .green : .red)
                    .frame(width: 10, height: 10)
            }
        }
        .task {
            pingInProgress = true

            do {
                try await pluginManager.kodi.ping(server: server)
                isActive = true
            } catch {
                logManager.error("Kodi server \(server.name): \(error)", showToast: false)
                isActive = false
            }

            pingInProgress = false
        }
    }
}

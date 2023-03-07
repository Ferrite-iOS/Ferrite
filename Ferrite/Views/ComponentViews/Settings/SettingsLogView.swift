//
//  SettingsLogView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/8/23.
//

import SwiftUI

struct SettingsLogView: View {
    @EnvironmentObject var logManager: LoggingManager

    var body: some View {
        NavView {
            List {
                ForEach(logManager.messageArray, id: \.self) { log in
                    Text(log.toMessage())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsLogView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsLogView()
    }
}

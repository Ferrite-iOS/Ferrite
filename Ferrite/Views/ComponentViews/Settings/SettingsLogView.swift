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
        List {
            ForEach($logManager.messageArray, id: \.self) { $log in
                Text(log.toMessage())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(log.isExpanded ? nil : 5)
                    .onTapGesture {
                        log.isExpanded.toggle()
                    }
            }
        }
        .listStyle(.plain)
        .alert("Success", isPresented: $logManager.showLogExportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Log successfully exported in Ferrite's logs folder")
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        logManager.exportLogs()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        logManager.messageArray = []
                    } label: {
                        Label("Clear session logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
}

struct SettingsLogView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsLogView()
    }
}

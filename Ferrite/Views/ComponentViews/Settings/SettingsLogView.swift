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
        .backport.alert(
            isPresented: $logManager.showLogExportedAlert,
            title: "Success",
            message: "Log successfully exported in Ferrite's logs folder"
        )
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

                    if #available(iOS 15, *) {
                        Button(role: .destructive) {
                            logManager.messageArray = []
                        } label: {
                            Label("Clear session logs", systemImage: "trash")
                        }
                    } else {
                        Button {
                            logManager.messageArray = []
                        } label: {
                            Label("Clear session logs", systemImage: "trash")
                        }
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

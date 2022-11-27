//
//  BackupsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/16/22.
//

import SwiftUI

struct BackupsView: View {
    @EnvironmentObject var backupManager: BackupManager
    @EnvironmentObject var navModel: NavigationViewModel

    @State private var selectedBackupUrl: URL?
    @State private var showRestoreAlert = false
    @State private var showRestoreCompletedAlert = false

    var body: some View {
        ZStack {
            if backupManager.backupUrls.isEmpty {
                EmptyInstructionView(title: "No Backups", message: "Create one using the + button in the top-right")
            } else {
                List {
                    ForEach(backupManager.backupUrls, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            backupManager.selectedBackupUrl = url
                            backupManager.showRestoreAlert.toggle()
                        }
                        .contextMenu {
                            Button {
                                navModel.activityItems = [url]
                                navModel.currentChoiceSheet = .activity
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                        }
                        .backport.tint(.primary)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            if let url = backupManager.backupUrls[safe: index] {
                                backupManager.removeBackup(backupUrl: url, index: index)
                            }
                        }
                    }
                }
                .inlinedList()
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            backupManager.backupUrls = FileManager.default.appDirectory
                .appendingPathComponent("Backups", isDirectory: true).contentsByDateAdded
        }
        .navigationTitle("Backups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    backupManager.createBackup()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct BackupsView_Previews: PreviewProvider {
    static var previews: some View {
        BackupsView()
    }
}

//
//  MainView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var logManager: LoggingManager
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var backupManager: BackupManager
    @EnvironmentObject var pluginManager: PluginManager

    @AppStorage("Updates.AutomaticNotifs") var autoUpdateNotifs = true

    @State private var showUpdateAlert = false
    @State private var releaseVersionString: String = ""
    @State private var releaseUrlString: String = ""

    var body: some View {
        TabView(selection: $navModel.selectedTab) {
            ContentView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationViewModel.ViewTab.search)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.closed")
                }
                .tag(NavigationViewModel.ViewTab.library)

            PluginsView()
                .tabItem {
                    Label("Plugins", systemImage: "doc.text")
                }
                .tag(NavigationViewModel.ViewTab.plugins)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(NavigationViewModel.ViewTab.settings)
        }
        .sheet(item: $navModel.currentChoiceSheet) { item in
            switch item {
            case .action:
                ActionChoiceView()
            case .batch:
                BatchChoiceView()
            case .activity:
                EmptyView()
                // TODO: Fix share sheet
                if #available(iOS 16, *) {
                    ShareSheet(activityItems: navModel.activityItems)
                        .presentationDetents([.medium, .large])
                } else {
                    ShareSheet(activityItems: navModel.activityItems)
                }
            }
        }
        .onAppear {
            logManager.info("Ferrite started")
        }
        .task {
            if
                autoUpdateNotifs,
                Application.shared.osVersion.toString() >= Application.shared.minVersion
            {
                // MARK: If scope bar duplication happens, this may be the problem
                // Sleep for 2 seconds to allow for view layout and app init
                try? await Task.sleep(seconds: 2)

                do {
                    guard let latestRelease = try await Github().fetchLatestRelease() else {
                        logManager.error(
                            "Github: No releases found",
                            description: "Github error: No releases found"
                        )
                        return
                    }

                    let releaseVersion = String(latestRelease.tagName.dropFirst())
                    if releaseVersion > Application.shared.appVersion {
                        releaseVersionString = latestRelease.tagName
                        releaseUrlString = latestRelease.htmlUrl

                        logManager.info("Update available to \(releaseVersionString)")
                        showUpdateAlert.toggle()
                    }
                } catch {
                    let error = error as NSError

                    if error.code == -1009 {
                        logManager.info(
                            "Github: The connection is offline",
                            description: "The connection is offline"
                        )
                    } else {
                        logManager.error(
                            "Github: \(error)",
                            description: "A Github error was logged"
                        )
                    }
                }

                logManager.info("Github release updates checked")
            }
        }
        .onOpenURL { url in
            if url.scheme == "file" {
                // Attempt to copy to backups directory if backup doesn't exist
                backupManager.copyBackup(backupUrl: url)

                backupManager.showRestoreAlert.toggle()
            }
        }
        // Global alerts and dialogs for backups
        .confirmationDialog(
            "Restore backup?",
            isPresented: $backupManager.showRestoreAlert,
            titleVisibility: .visible
        ) {
            Button("Merge", role: .destructive) {
                Task {
                    await backupManager.restoreBackup(pluginManager: pluginManager, doOverwrite: false)
                }
            }
            Button("Overwrite", role: .destructive) {
                Task {
                    await backupManager.restoreBackup(pluginManager: pluginManager, doOverwrite: true)
                }
            }
        } message: {
            Text(
                "Merge (preferred): Will merge your current data with the backup \n\n" +
                    "Overwrite: Will delete and replace all your data \n\n" +
                    "If Merge causes app instability, uninstall Ferrite and use the Overwrite option."
            )
        }
        .alert("Backup restored", isPresented: $backupManager.showRestoreCompletedAlert) {
            Button("OK", role: .cancel) {
                backupManager.restoreCompletedMessage = []
            }
        } message: {
            Text(backupManager.restoreCompletedMessage.joined(separator: " \n\n"))
        }
        // Updater alert
        .alert("Update available", isPresented: $showUpdateAlert) {
            Button("Download") {
                guard let releaseUrl = URL(string: releaseUrlString) else {
                    return
                }

                UIApplication.shared.open(releaseUrl)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Ferrite \(releaseVersionString) can be downloaded. \n\n" +
                    "This alert can be disabled in Settings."
            )
        }
        .overlay {
            VStack {
                Spacer()
                if logManager.showToast {
                    Group {
                        switch logManager.toastType {
                        case .info:
                            Text(logManager.toastDescription ?? "This shouldn't be showing up... Contact the dev!")
                        case .warn:
                            Text("Warn: \(logManager.toastDescription ?? "This shouldn't be showing up... Contact the dev!")")
                        case .error:
                            Text("Error: \(logManager.toastDescription ?? "This shouldn't be showing up... Contact the dev!")")
                        }
                    }
                    .padding(12)
                    .font(.caption)
                    .background(.thinMaterial)
                    .cornerRadius(10)
                }

                if logManager.showIndeterminateToast {
                    VStack {
                        Text(logManager.indeterminateToastDescription ?? "Loading...")
                            .lineLimit(1)

                        HStack {
                            IndeterminateProgressView()

                            if let cancelAction = logManager.indeterminateCancelAction {
                                Button("Cancel") {
                                    cancelAction()
                                    logManager.hideIndeterminateToast()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .font(.caption)
                    .background(.thinMaterial)
                    .cornerRadius(10)
                    .frame(width: 200)
                }

                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 60)
            }
            .animation(.easeInOut(duration: 0.3), value: logManager.showToast || logManager.showIndeterminateToast)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

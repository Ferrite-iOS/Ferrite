//
//  MainView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI
import SwiftUIX

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
    @State private var viewTask: Task<Void, Never>?

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
                    .environmentObject(debridManager)
                    .environmentObject(scrapingModel)
                    .environmentObject(navModel)
                    .environmentObject(pluginManager)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            case .batch:
                BatchChoiceView()
                    .environmentObject(debridManager)
                    .environmentObject(scrapingModel)
                    .environmentObject(navModel)
            case .activity:
                if #available(iOS 16, *) {
                    AppActivityView(activityItems: navModel.activityItems)
                        .presentationDetents([.medium, .large])
                } else {
                    AppActivityView(activityItems: navModel.activityItems)
                }
            }
        }
        .backport.onAppear {
            if
                autoUpdateNotifs,
                Application.shared.osVersion.majorVersion >= Application.shared.minVersion.majorVersion
            {
                // MARK: If scope bar duplication happens, this may be the problem

                logManager.info("Ferrite started")

                viewTask = Task {
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
        }
        .onDisappear {
            viewTask?.cancel()
        }
        .onOpenURL { url in
            if url.scheme == "file" {
                // Attempt to copy to backups directory if backup doesn't exist
                backupManager.copyBackup(backupUrl: url)

                backupManager.showRestoreAlert.toggle()
            }
        }
        // Global alerts and dialogs for backups
        .backport.confirmationDialog(
            isPresented: $backupManager.showRestoreAlert,
            title: "Restore backup?",
            message:
            "Merge (preferred): Will merge your current data with the backup \n\n" +
                "Overwrite: Will delete and replace all your data \n\n" +
                "If Merge causes app instability, uninstall Ferrite and use the Overwrite option.",
            buttons: [
                .init("Merge", role: .destructive) {
                    Task {
                        await backupManager.restoreBackup(pluginManager: pluginManager, doOverwrite: false)
                    }
                },
                .init("Overwrite", role: .destructive) {
                    Task {
                        await backupManager.restoreBackup(pluginManager: pluginManager, doOverwrite: true)
                    }
                }
            ]
        )
        .backport.alert(
            isPresented: $backupManager.showRestoreCompletedAlert,
            title: "Backup restored",
            message: backupManager.restoreCompletedMessage.joined(separator: " \n\n"),
            buttons: [
                .init("OK") {
                    backupManager.restoreCompletedMessage = []
                }
            ]
        )
        // Updater alert
        .backport.alert(
            isPresented: $showUpdateAlert,
            title: "Update available",
            message:
            "Ferrite \(releaseVersionString) can be downloaded. \n\n" +
                "This alert can be disabled in Settings.",
            buttons: [
                .init("Download") {
                    guard let releaseUrl = URL(string: releaseUrlString) else {
                        return
                    }

                    UIApplication.shared.open(releaseUrl)
                },
                .init(role: .cancel)
            ]
        )
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
                    .background {
                        VisualEffectBlurView(blurStyle: .systemThinMaterial)
                    }
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
                    .background {
                        VisualEffectBlurView(blurStyle: .systemThinMaterial)
                    }
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

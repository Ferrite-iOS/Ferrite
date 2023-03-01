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
    @EnvironmentObject var toastModel: ToastViewModel
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
            if autoUpdateNotifs {
                viewTask = Task {
                    do {
                        guard let latestRelease = try await Github().fetchLatestRelease() else {
                            toastModel.updateToastDescription("Github error: No releases found")
                            return
                        }

                        let releaseVersion = String(latestRelease.tagName.dropFirst())
                        if releaseVersion > Application.shared.appVersion {
                            releaseVersionString = latestRelease.tagName
                            releaseUrlString = latestRelease.htmlUrl
                            showUpdateAlert.toggle()
                        }
                    } catch {
                        toastModel.updateToastDescription("Github error: \(error)")
                    }
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
                if toastModel.showToast {
                    Group {
                        switch toastModel.toastType {
                        case .info:
                            Text(toastModel.toastDescription ?? "This shouldn't be showing up... Contact the dev!")
                        case .error:
                            Text("Error: \(toastModel.toastDescription ?? "This shouldn't be showing up... Contact the dev!")")
                        }
                    }
                    .padding(12)
                    .font(.caption)
                    .background {
                        VisualEffectBlurView(blurStyle: .systemThinMaterial)
                    }
                    .cornerRadius(10)
                }

                if toastModel.showIndeterminateToast {
                    VStack {
                        Text(toastModel.indeterminateToastDescription ?? "Loading...")

                        HStack {
                            IndeterminateProgressView()

                            if let cancelAction = toastModel.indeterminateCancelAction {
                                Button("Cancel") {
                                    cancelAction()
                                    toastModel.hideIndeterminateToast()
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
            .animation(.easeInOut(duration: 0.3), value: toastModel.showToast || toastModel.showIndeterminateToast)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

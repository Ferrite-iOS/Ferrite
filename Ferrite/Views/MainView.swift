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
                .tag(ViewTab.search)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.closed")
                }
                .tag(ViewTab.library)

            SourcesView()
                .tabItem {
                    Label("Sources", systemImage: "doc.text")
                }
                .tag(ViewTab.sources)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(ViewTab.settings)
        }
        .sheet(item: $navModel.currentChoiceSheet) { item in
            switch item {
            case .magnet:
                MagnetChoiceView()
                    .environmentObject(debridManager)
                    .environmentObject(scrapingModel)
                    .environmentObject(navModel)
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
        .onAppear {
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
        // Global alerts for backups
        .backport.alert(
            isPresented: $backupManager.showRestoreAlert,
            title: "Restore backup?",
            message: "Restoring this backup will merge all your data!",
            buttons: [
                .init("Restore", role: .destructive) {
                    backupManager.restoreBackup()
                },
                .init(role: .cancel)
            ]
        )
        .backport.alert(
            isPresented: $backupManager.showRestoreCompletedAlert,
            title: "Backup restored",
            message: backupManager.backupSourceNames.isEmpty ?
                "No sources need to be reinstalled" :
                "Reinstall sources: \(backupManager.backupSourceNames.joined(separator: ", "))"
        )
        // Updater alert
        .backport.alert(
            isPresented: $showUpdateAlert,
            title: "Update available",
            message: "Ferrite \(releaseVersionString) can be downloaded. \n\n This alert can be disabled in Settings.",
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

                if debridManager.showLoadingProgress {
                    VStack {
                        Text("Loading content")

                        HStack {
                            IndeterminateProgressView()

                            Button("Cancel") {
                                debridManager.currentDebridTask?.cancel()
                                debridManager.currentDebridTask = nil
                                debridManager.showLoadingProgress = false
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
            .animation(.easeInOut(duration: 0.3), value: toastModel.showToast || debridManager.showLoadingProgress)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

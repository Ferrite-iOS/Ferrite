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
        .dynamicAlert(
            isPresented: $showUpdateAlert,
            title: "Update available",
            message: "Ferrite \(releaseVersionString) can be downloaded. \n\n This alert can be disabled in Settings.",
            buttons: [
                AlertButton("Download") {
                    guard let releaseUrl = URL(string: releaseUrlString) else {
                        return
                    }

                    UIApplication.shared.open(releaseUrl)
                },
                AlertButton(role: .cancel)
            ]
        )
        .onAppear {
            if autoUpdateNotifs {
                viewTask = Task {
                    do {
                        guard let latestRelease = try await Github().fetchLatestRelease() else {
                            toastModel.updateToastDescription("Github error: No releases found")
                            return
                        }

                        let releaseVersion = String(latestRelease.tagName.dropFirst())
                        if releaseVersion > UIApplication.shared.appVersion {
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

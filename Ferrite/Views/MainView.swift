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

    var body: some View {
        TabView(selection: $navModel.selectedTab) {
            ContentView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(ViewTab.search)

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

//
//  MainView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var toastModel: ToastViewModel

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
                    GroupBox {
                        switch toastModel.toastType {
                        case .info:
                            Text(toastModel.toastDescription ?? "This shouldn't be showing up... Contact the dev!")
                        case .error:
                            Text("Error: \(toastModel.toastDescription ?? "This shouldn't be showing up... Contact the dev!")")
                        }
                    }
                    .groupBoxStyle(ErrorGroupBoxStyle())

                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 60)
                }
            }
            .font(.caption)
            .animation(.easeInOut(duration: 0.3), value: toastModel.showToast)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

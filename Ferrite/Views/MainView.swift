//
//  MainView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/11/22.
//

import SwiftUI

enum Tab {
    case search
    case settings
}

struct MainView: View {
    @EnvironmentObject var toastModel: ToastViewModel

    @State private var tabSelection: Tab = .search

    var body: some View {
        TabView(selection: $tabSelection) {
            ContentView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
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
                }
            }
            .transition(AnyTransition.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.3), value: true)
            .padding()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

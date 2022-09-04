//
//  SettingsAppVersionView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/29/22.
//

import SwiftUI
import SwiftUIX

struct SettingsAppVersionView: View {
    @EnvironmentObject var toastModel: ToastViewModel

    @State private var viewTask: Task<Void, Never>?
    @State private var releases: [GithubRelease] = []

    var body: some View {
        ZStack {
            if releases.isEmpty {
                ActivityIndicator()
            } else {
                List {
                    Section(header: Text("GitHub links")) {
                        ForEach(releases, id: \.self) { release in
                            ListRowLinkView(text: release.tagName, link: release.htmlUrl)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            viewTask = Task {
                do {
                    if let fetchedReleases = try await Github().fetchReleases() {
                        withAnimation {
                            releases = fetchedReleases
                        }
                    } else {
                        toastModel.updateToastDescription("Github error: No releases found")
                    }
                } catch {
                    toastModel.updateToastDescription("Github error: \(error)")
                }
            }
        }
        .onDisappear {
            viewTask?.cancel()
        }
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsAppVersionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAppVersionView()
    }
}

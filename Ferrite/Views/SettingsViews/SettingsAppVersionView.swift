//
//  SettingsAppVersionView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/29/22.
//

import SwiftUI

struct SettingsAppVersionView: View {
    @EnvironmentObject var toastModel: ToastViewModel

    @State private var viewTask: Task<Void, Never>?
    @State private var releases: [GithubRelease] = []

    var body: some View {
        List {
            Section(header: Text("GitHub links")) {
                ForEach(releases, id: \.self) { release in
                    ListRowLinkView(text: release.tagName, link: release.htmlUrl)
                }
            }
        }
        .onAppear {
            viewTask = Task {
                do {
                    if let fetchedReleases = try await Github().fetchReleases() {
                        releases = fetchedReleases
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
        .listStyle(.insetGrouped)
        .navigationTitle("Version history")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsAppVersionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAppVersionView()
    }
}

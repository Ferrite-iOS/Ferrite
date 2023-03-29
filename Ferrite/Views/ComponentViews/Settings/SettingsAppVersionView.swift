//
//  SettingsAppVersionView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/29/22.
//

import SwiftUI

struct SettingsAppVersionView: View {
    @EnvironmentObject var logManager: LoggingManager

    @State private var releases: [Github.Release] = []

    @State private var loadedReleases = false

    var body: some View {
        ZStack {
            if !loadedReleases {
                ProgressView()
            } else if !releases.isEmpty {
                List {
                    Section(header: InlineHeader("GitHub links")) {
                        ForEach(releases, id: \.self) { release in
                            ListRowLinkView(text: release.tagName, link: release.htmlUrl)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .task {
            do {
                if let fetchedReleases = try await Github().fetchReleases() {
                    releases = fetchedReleases
                } else {
                    logManager.error("Github: No releases found")
                }
            } catch {
                logManager.error("Github: \(error)")
            }

            withAnimation {
                loadedReleases = true
            }
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

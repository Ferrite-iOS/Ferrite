//
//  GithubWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/28/22.
//

import Foundation

public class Github {
    public func fetchLatestRelease() async throws -> Release? {
        let url = URL(string: "https://api.github.com/repos/Ferrite-iOS/Ferrite/releases/latest")!

        let (data, _) = try await URLSession.shared.data(from: url)

        let rawResponse = try JSONDecoder().decode(Release.self, from: data)
        return rawResponse
    }

    public func fetchReleases() async throws -> [Release]? {
        let url = URL(string: "https://api.github.com/repos/Ferrite-iOS/Ferrite/releases")!

        let (data, _) = try await URLSession.shared.data(from: url)

        let rawResponse = try JSONDecoder().decode([Release].self, from: data)
        return rawResponse
    }
}

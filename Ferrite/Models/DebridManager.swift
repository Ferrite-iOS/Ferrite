//
//  DebridManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import Foundation
import SwiftUI

public class DebridManager: ObservableObject {
    // UI Variables
    var toastModel: ToastViewModel? = nil
    @Published var showWebView: Bool = false

    // RealDebrid variables
    let realDebrid: RealDebrid = RealDebrid()

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @Published var realDebridHashes: [String] = []
    @Published var realDebridAuthUrl: String = ""
    @Published var realDebridDownloadUrl: String = ""

    init() {
        realDebrid.parentManager = self
    }

    public func populateDebridHashes(_ searchResults: [SearchResult]) async {
        var hashes: [String] = []

        for result in searchResults {
            if let hash = result.magnetHash {
                hashes.append(hash)
            }
        }

        guard let debridHashes = await realDebrid.instantAvailability(magnetHashes: hashes) else {
            return
        }

        Task { @MainActor in
            realDebridHashes = debridHashes
        }
    }

    public func authenticateRd() async {
        do {
            let url = try await realDebrid.getVerificationInfo()

            Task { @MainActor in
                realDebridAuthUrl = url
                showWebView.toggle()
            }
        } catch {
            Task { @MainActor in
                toastModel?.toastDescription = "RealDebrid Authentication error: \(error)"
            }

            print(error)
        }
    }

    public func fetchRdDownload(searchResult: SearchResult) async {
        do {
            let realDebridId = try await realDebrid.addMagnet(magnetLink: searchResult.magnetLink)
            let httpResponse = try await realDebrid.selectFiles(debridID: realDebridId)

            if httpResponse?.statusCode != 204 {
                // Throw error here
                return
            }

            let torrentLink = try await realDebrid.torrentInfo(debridID: realDebridId)
            let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: torrentLink)

            Task { @MainActor in
                realDebridDownloadUrl = downloadLink
            }
        } catch {
            Task { @MainActor in
                toastModel?.toastDescription = "RealDebrid download error: \(error)"
            }

            print(error)
        }
    }
}

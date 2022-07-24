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
    var toastModel: ToastViewModel?
    @Published var showWebView: Bool = false

    // RealDebrid variables
    let realDebrid: RealDebrid = .init()

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    @Published var realDebridHashes: [RealDebridIA] = []
    @Published var realDebridAuthUrl: String = ""
    @Published var realDebridDownloadUrl: String = ""
    @Published var selectedRealDebridItem: RealDebridIA?
    @Published var selectedRealDebridFile: RealDebridIAFile?

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

        do {
            let debridHashes = try await realDebrid.instantAvailability(magnetHashes: hashes)

            Task { @MainActor in
                realDebridHashes = debridHashes
            }
        } catch {
            Task { @MainActor in
                toastModel?.toastDescription = "RealDebrid hash error: \(error)"
            }

            print(error)
        }
    }

    public func matchSearchResult(result: SearchResult?) -> RealDebridIAStatus {
        guard let result = result else {
            return .none
        }

        guard let debridMatch = realDebridHashes.first(where: { result.magnetHash == $0.hash }) else {
            return .none
        }

        if debridMatch.batches.isEmpty {
            return .full
        } else {
            return .partial
        }
    }

    @MainActor
    public func setSelectedRdResult(result: SearchResult) -> Bool {
        guard let magnetHash = result.magnetHash else {
            toastModel?.toastDescription = "Could not find the torrent magnet hash"
            return false
        }

        if let realDebridItem = realDebridHashes.first(where: { magnetHash == $0.hash }) {
            selectedRealDebridItem = realDebridItem
            return true
        } else {
            toastModel?.toastDescription = "Could not find the associated RealDebrid entry for magnet hash \(magnetHash)"
            return false
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

    public func fetchRdDownload(searchResult: SearchResult, iaFile: RealDebridIAFile? = nil) async {
        do {
            let realDebridId = try await realDebrid.addMagnet(magnetLink: searchResult.magnetLink)

            var fileIds: [Int] = []

            if let iaFile = iaFile {
                guard let iaBatchFromFile = selectedRealDebridItem?.batches[safe: iaFile.batchIndex] else {
                    return
                }

                fileIds = iaBatchFromFile.files.map(\.id)
            }

            try await realDebrid.selectFiles(debridID: realDebridId, fileIds: fileIds)

            let torrentLink = try await realDebrid.torrentInfo(debridID: realDebridId, selectedIndex: iaFile == nil ? 0 : iaFile?.batchFileIndex)
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

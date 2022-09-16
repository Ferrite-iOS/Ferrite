//
//  DebridManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import Foundation
import SwiftUI

@MainActor
public class DebridManager: ObservableObject {
    // Linked classes
    var toastModel: ToastViewModel?
    let realDebrid: RealDebrid = .init()

    // UI Variables
    @Published var showWebView: Bool = false
    @Published var showLoadingProgress: Bool = false

    // Service agnostic variables
    var currentDebridTask: Task<Void, Never>?

    // RealDebrid auth variables
    var realDebridEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(realDebridEnabled, forKey: "RealDebrid.Enabled")
        }
    }

    @Published var realDebridAuthProcessing: Bool = false
    var realDebridAuthUrl: String = ""

    // RealDebrid fetch variables
    @Published var realDebridIAValues: [RealDebridIA] = []
    var realDebridDownloadUrl: String = ""

    @Published var showDeleteAlert: Bool = false

    // TODO: Switch to an individual item based sheet system to remove these variables
    var selectedRealDebridItem: RealDebridIA?
    var selectedRealDebridFile: RealDebridIAFile?
    var selectedRealDebridID: String?

    init() {
        realDebridEnabled = UserDefaults.standard.bool(forKey: "RealDebrid.Enabled")
    }

    public func populateDebridHashes(_ resultHashes: [String]) async {
        do {
            let now = Date()

            // If a hash isn't found in the IA, update it
            // If the hash is expired, remove it and update it
            let sendHashes = resultHashes.filter { hash in
                if let IAIndex = realDebridIAValues.firstIndex(where: { $0.hash == hash }) {
                    if now.timeIntervalSince1970 > realDebridIAValues[IAIndex].expiryTimeStamp {
                        realDebridIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }

            if !sendHashes.isEmpty {
                let fetchedIAValues = try await realDebrid.instantAvailability(magnetHashes: sendHashes)

                realDebridIAValues += fetchedIAValues
            }
        } catch {
            let error = error as NSError

            if error.code != -999 {
                toastModel?.updateToastDescription("RealDebrid hash error: \(error)")
            }

            print("RealDebrid hash error: \(error)")
        }
    }

    public func matchSearchResult(result: SearchResult?) -> RealDebridIAStatus {
        guard let result = result else {
            return .none
        }

        guard let debridMatch = realDebridIAValues.first(where: { result.magnetHash == $0.hash }) else {
            return .none
        }

        if debridMatch.batches.isEmpty {
            return .full
        } else {
            return .partial
        }
    }

    public func setSelectedRdResult(result: SearchResult) -> Bool {
        guard let magnetHash = result.magnetHash else {
            toastModel?.updateToastDescription("Could not find the torrent magnet hash")
            return false
        }

        if let realDebridItem = realDebridIAValues.first(where: { magnetHash == $0.hash }) {
            selectedRealDebridItem = realDebridItem
            return true
        } else {
            toastModel?.updateToastDescription("Could not find the associated RealDebrid entry for magnet hash \(magnetHash)")
            return false
        }
    }

    public func authenticateRd() async {
        do {
            realDebridAuthProcessing = true
            let verificationResponse = try await realDebrid.getVerificationInfo()

            realDebridAuthUrl = verificationResponse.directVerificationURL
            showWebView.toggle()

            try await realDebrid.getDeviceCredentials(deviceCode: verificationResponse.deviceCode)

            realDebridEnabled = true
        } catch {
            toastModel?.updateToastDescription("RealDebrid authentication error: \(error)")
            realDebrid.authTask?.cancel()

            print("RealDebrid authentication error: \(error)")
        }
    }

    public func logoutRd() async {
        do {
            try await realDebrid.deleteTokens()
            realDebridEnabled = false
            realDebridAuthProcessing = false
        } catch {
            toastModel?.updateToastDescription("RealDebrid logout error: \(error)")

            print("RealDebrid logout error: \(error)")
        }
    }

    public func fetchRdDownload(searchResult: SearchResult) async {
        defer {
            currentDebridTask = nil
            showLoadingProgress = false
        }

        showLoadingProgress = true

        guard let magnetLink = searchResult.magnetLink else {
            toastModel?.updateToastDescription("Could not run your action because the magnet link is invalid.")
            print("RealDebrid error: Invalid magnet link")

            return
        }

        do {
            var fileIds: [Int] = []

            if let iaFile = selectedRealDebridFile {
                guard let iaBatchFromFile = selectedRealDebridItem?.batches[safe: iaFile.batchIndex] else {
                    return
                }

                fileIds = iaBatchFromFile.files.map(\.id)
            }

            // If there's an existing torrent, check for a download link. Otherwise check for an unrestrict link
            let existingTorrents = try await realDebrid.userTorrents().filter { $0.hash == selectedRealDebridItem?.hash }

            // If the links match from a user's downloads, no need to re-run a download
            if let existingTorrent = existingTorrents[safe: 0],
                let torrentLink = existingTorrent.links[safe: selectedRealDebridFile?.batchFileIndex ?? 0]
            {
                let existingLinks = try await realDebrid.userDownloads().filter { $0.link == torrentLink }
                if let existingLink = existingLinks[safe: 0]?.download {
                    realDebridDownloadUrl = existingLink
                } else {
                    let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: torrentLink)

                    realDebridDownloadUrl = downloadLink
                }

            } else {
                // Add a magnet after all the cache checks fail
                selectedRealDebridID = try await realDebrid.addMagnet(magnetLink: magnetLink)

                if let realDebridId = selectedRealDebridID {
                    try await realDebrid.selectFiles(debridID: realDebridId, fileIds: fileIds)

                    let torrentLink = try await realDebrid.torrentInfo(debridID: realDebridId, selectedIndex: selectedRealDebridFile?.batchFileIndex ?? 0)
                    let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: torrentLink)

                    realDebridDownloadUrl = downloadLink
                } else {
                    toastModel?.updateToastDescription("Could not cache this torrent. Aborting.")
                }
            }
        } catch {
            switch error {
            case RealDebridError.EmptyTorrents:
                showDeleteAlert.toggle()
            default:
                let error = error as NSError

                switch error.code {
                case -999:
                    toastModel?.updateToastDescription("Download cancelled", newToastType: .info)
                default:
                    toastModel?.updateToastDescription("RealDebrid download error: \(error)")
                }

                await deleteRdTorrent()
            }

            showLoadingProgress = false

            print("RealDebrid download error: \(error)")
        }
    }

    public func deleteRdTorrent() async {
        if let realDebridId = selectedRealDebridID {
            try? await realDebrid.deleteTorrent(debridID: realDebridId)
        }

        selectedRealDebridID = nil
    }
}

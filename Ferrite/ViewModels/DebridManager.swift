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
    let allDebrid: AllDebrid = .init()

    // UI Variables
    @Published var showWebView: Bool = false
    @Published var showLoadingProgress: Bool = false

    // Service agnostic variables
    @Published var enabledDebrids: Set<DebridType> = [] {
        didSet {
            UserDefaults.standard.set(enabledDebrids.rawValue, forKey: "Debrid.EnabledArray")
        }
    }

    @Published var selectedDebridType: DebridType? {
        didSet {
            UserDefaults.standard.set(selectedDebridType?.rawValue ?? 0, forKey: "Debrid.PreferredService")
        }
    }

    var currentDebridTask: Task<Void, Never>?
    var downloadUrl: String = ""
    var authUrl: String = ""

    // RealDebrid auth variables
    @Published var realDebridAuthProcessing: Bool = false

    // RealDebrid fetch variables
    @Published var realDebridIAValues: [RealDebrid.IA] = []

    @Published var showDeleteAlert: Bool = false

    var selectedRealDebridItem: RealDebrid.IA?
    var selectedRealDebridFile: RealDebrid.IAFile?
    var selectedRealDebridID: String?

    // AllDebrid auth variables
    @Published var allDebridAuthProcessing: Bool = false

    // AllDebrid fetch variables
    @Published var allDebridIAValues: [AllDebrid.IA] = []

    var selectedAllDebridItem: AllDebrid.IA?
    var selectedAllDebridFile: AllDebrid.IAFile?

    init() {
        if let rawDebridList = UserDefaults.standard.string(forKey: "Debrid.EnabledArray"),
           let serializedDebridList = Set<DebridType>(rawValue: rawDebridList)
        {
            enabledDebrids = serializedDebridList
        }

        // If a UserDefaults integer isn't set, it's usually 0
        let rawPreferredService = UserDefaults.standard.integer(forKey: "Debrid.PreferredService")
        selectedDebridType = DebridType(rawValue: rawPreferredService)

        // If a user has one logged in service, automatically set the preferred service to that one
        if enabledDebrids.count == 1 {
            selectedDebridType = enabledDebrids.first
        }
    }

    // TODO: Remove this after v0.6.0
    // Login cleanup function that's automatically run to switch to the new login system
    public func cleanupOldLogins() async {
        let realDebridEnabled = UserDefaults.standard.bool(forKey: "RealDebrid.Enabled")
        if realDebridEnabled {
            enabledDebrids.insert(.realDebrid)
            UserDefaults.standard.set(false, forKey: "RealDebrid.Enabled")
        }

        let allDebridEnabled = UserDefaults.standard.bool(forKey: "AllDebrid.Enabled")
        if allDebridEnabled {
            enabledDebrids.insert(.allDebrid)
            UserDefaults.standard.set(false, forKey: "AllDebrid.Enabled")
        }
    }

    // Common function to populate hashes for debrid services
    public func populateDebridHashes(_ resultHashes: [String]) async {
        do {
            let now = Date()

            // If a hash isn't found in the IA, update it
            // If the hash is expired, remove it and update it
            let sendHashes = resultHashes.filter { hash in
                if let IAIndex = realDebridIAValues.firstIndex(where: { $0.hash == hash }), enabledDebrids.contains(.realDebrid) {
                    if now.timeIntervalSince1970 > realDebridIAValues[IAIndex].expiryTimeStamp {
                        realDebridIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else if let IAIndex = allDebridIAValues.firstIndex(where: { $0.hash == hash }), enabledDebrids.contains(.allDebrid) {
                    if now.timeIntervalSince1970 > allDebridIAValues[IAIndex].expiryTimeStamp {
                        allDebridIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }

            if !sendHashes.isEmpty {
                if enabledDebrids.contains(.realDebrid) {
                    let fetchedRealDebridIA = try await realDebrid.instantAvailability(magnetHashes: sendHashes)
                    realDebridIAValues += fetchedRealDebridIA
                }

                if enabledDebrids.contains(.allDebrid) {
                    let fetchedAllDebridIA = try await allDebrid.instantAvailability(hashes: sendHashes)
                    allDebridIAValues += fetchedAllDebridIA
                }
            }
        } catch {
            let error = error as NSError

            if error.code != -999 {
                toastModel?.updateToastDescription("Hash population error: \(error)")
            }

            print("Hash population error: \(error)")
        }
    }

    // Common function to match search results with a provided debrid service
    public func matchSearchResult(result: SearchResult?) -> IAStatus {
        guard let result else {
            return .none
        }

        switch selectedDebridType {
        case .realDebrid:
            guard let realDebridMatch = realDebridIAValues.first(where: { result.magnetHash == $0.hash }) else {
                return .none
            }

            if realDebridMatch.batches.isEmpty {
                return .full
            } else {
                return .partial
            }
        case .allDebrid:
            guard let allDebridMatch = allDebridIAValues.first(where: { result.magnetHash == $0.hash }) else {
                return .none
            }

            if allDebridMatch.files.count > 1 {
                return .partial
            } else {
                return .full
            }
        case .none:
            return .none
        }
    }

    public func selectDebridResult(result: SearchResult) -> Bool {
        guard let magnetHash = result.magnetHash else {
            toastModel?.updateToastDescription("Could not find the torrent magnet hash")
            return false
        }

        switch selectedDebridType {
        case .realDebrid:
            if let realDebridItem = realDebridIAValues.first(where: { magnetHash == $0.hash }) {
                selectedRealDebridItem = realDebridItem
                return true
            } else {
                toastModel?.updateToastDescription("Could not find the associated RealDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .allDebrid:
            if let allDebridItem = allDebridIAValues.first(where: { magnetHash == $0.hash }) {
                selectedAllDebridItem = allDebridItem
                return true
            } else {
                toastModel?.updateToastDescription("Could not find the associated AllDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .none:
            return false
        }
    }

    // MARK: - Authentication UI linked functions

    // Common function to delegate what debrid service to authenticate with
    public func authenticateDebrid(debridType: DebridType) async {
        switch debridType {
        case .realDebrid:
            await authenticateRd()
            enabledDebrids.insert(.realDebrid)
        case .allDebrid:
            await authenticateAd()
            enabledDebrids.insert(.allDebrid)
        }

        // Automatically sets the preferred debrid service if only one login is provided
        if enabledDebrids.count == 1 {
            selectedDebridType = enabledDebrids.first
        }
    }

    private func authenticateRd() async {
        do {
            realDebridAuthProcessing = true
            let verificationResponse = try await realDebrid.getVerificationInfo()

            authUrl = verificationResponse.directVerificationURL
            showWebView.toggle()

            try await realDebrid.getDeviceCredentials(deviceCode: verificationResponse.deviceCode)
        } catch {
            toastModel?.updateToastDescription("RealDebrid authentication error: \(error)")
            realDebrid.authTask?.cancel()

            print("RealDebrid authentication error: \(error)")
        }
    }

    private func authenticateAd() async {
        do {
            allDebridAuthProcessing = true
            let pinResponse = try await allDebrid.getPinInfo()

            authUrl = pinResponse.userURL
            showWebView.toggle()

            try await allDebrid.getApiKey(checkID: pinResponse.check, pin: pinResponse.pin)
        } catch {
            toastModel?.updateToastDescription("AllDebrid authentication error: \(error)")
            allDebrid.authTask?.cancel()

            print("AllDebrid authentication error: \(error)")
        }
    }

    // MARK: - Logout UI linked functions

    // Common function to delegate what debrid service to logout of
    public func logoutDebrid(debridType: DebridType) async {
        switch debridType {
        case .realDebrid:
            await logoutRd()
        case .allDebrid:
            logoutAd()
        }

        // Automatically resets the preferred debrid service if it was set to the logged out service
        if selectedDebridType == debridType {
            selectedDebridType = nil
        }
    }

    private func logoutRd() async {
        do {
            try await realDebrid.deleteTokens()
            enabledDebrids.remove(.realDebrid)
            realDebridAuthProcessing = false
        } catch {
            toastModel?.updateToastDescription("RealDebrid logout error: \(error)")

            print("RealDebrid logout error: \(error)")
        }
    }

    private func logoutAd() {
        allDebrid.deleteTokens()
        enabledDebrids.remove(.allDebrid)
        allDebridAuthProcessing = false

        toastModel?.updateToastDescription("Please manually delete the AllDebrid API key", newToastType: .info)
    }

    // MARK: - Debrid fetch UI linked functions

    // Common function to delegate what debrid service to fetch from
    public func fetchDebridDownload(searchResult: SearchResult) async {
        defer {
            currentDebridTask = nil
            showLoadingProgress = false
        }

        showLoadingProgress = true

        guard let magnetLink = searchResult.magnetLink else {
            toastModel?.updateToastDescription("Could not run your action because the magnet link is invalid.")
            print("Debrid error: Invalid magnet link")

            return
        }

        switch selectedDebridType {
        case .realDebrid:
            await fetchRdDownload(magnetLink: magnetLink)
        case .allDebrid:
            await fetchAdDownload(magnetLink: magnetLink)
        case .none:
            break
        }
    }

    func fetchRdDownload(magnetLink: String) async {
        print("Called RD Download function!")

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
                    downloadUrl = existingLink
                } else {
                    let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: torrentLink)

                    downloadUrl = downloadLink
                }

            } else {
                // Add a magnet after all the cache checks fail
                selectedRealDebridID = try await realDebrid.addMagnet(magnetLink: magnetLink)

                if let realDebridId = selectedRealDebridID {
                    try await realDebrid.selectFiles(debridID: realDebridId, fileIds: fileIds)

                    let torrentLink = try await realDebrid.torrentInfo(
                        debridID: realDebridId,
                        selectedIndex: selectedRealDebridFile?.batchFileIndex ?? 0
                    )
                    let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: torrentLink)

                    downloadUrl = downloadLink
                } else {
                    toastModel?.updateToastDescription("Could not cache this torrent. Aborting.")
                }
            }
        } catch {
            switch error {
            case RealDebrid.RDError.EmptyTorrents:
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

    func deleteRdTorrent() async {
        if let realDebridId = selectedRealDebridID {
            try? await realDebrid.deleteTorrent(debridID: realDebridId)
        }

        selectedRealDebridID = nil
    }

    func fetchAdDownload(magnetLink: String) async {
        do {
            let magnetID = try await allDebrid.addMagnet(magnetLink: magnetLink)
            let lockedLink = try await allDebrid.fetchMagnetStatus(
                magnetId: magnetID,
                selectedIndex: selectedAllDebridFile?.id ?? 0
            )
            let unlockedLink = try await allDebrid.unlockLink(lockedLink: lockedLink)

            downloadUrl = unlockedLink
        } catch {
            let error = error as NSError
            switch error.code {
            case -999:
                toastModel?.updateToastDescription("Download cancelled", newToastType: .info)
            default:
                toastModel?.updateToastDescription("AllDebrid download error: \(error)")
            }
        }
    }
}

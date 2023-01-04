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
    let premiumize: Premiumize = .init()

    // UI Variables
    @Published var showWebView: Bool = false
    @Published var showAuthSession: Bool = false
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
    var authUrl: URL?

    // RealDebrid auth variables
    @Published var realDebridAuthProcessing: Bool = false

    // RealDebrid fetch variables
    @Published var realDebridIAValues: [RealDebrid.IA] = []

    @Published var showDeleteAlert: Bool = false

    var selectedRealDebridItem: RealDebrid.IA?
    var selectedRealDebridFile: RealDebrid.IAFile?
    var selectedRealDebridID: String?

    // RealDebrid cloud variables
    @Published var realDebridCloudTorrents: [RealDebrid.UserTorrentsResponse] = []
    @Published var realDebridCloudDownloads: [RealDebrid.UserDownloadsResponse] = []
    var realDebridCloudTTL: Double = 0.0

    // AllDebrid auth variables
    @Published var allDebridAuthProcessing: Bool = false

    // AllDebrid fetch variables
    @Published var allDebridIAValues: [AllDebrid.IA] = []

    var selectedAllDebridItem: AllDebrid.IA?
    var selectedAllDebridFile: AllDebrid.IAFile?

    // Premiumize auth variables
    @Published var premiumizeAuthProcessing: Bool = false

    // Premiumize fetch variables
    @Published var premiumizeIAValues: [Premiumize.IA] = []

    var selectedPremiumizeItem: Premiumize.IA?
    var selectedPremiumizeFile: Premiumize.IAFile?

    // Premiumize cloud variables
    @Published var premiumizeCloudItems: [Premiumize.UserItem] = []
    var premiumizeCloudTTL: Double = 0.0

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

        let premiumizeEnabled = UserDefaults.standard.bool(forKey: "Premiumize.Enabled")
        if premiumizeEnabled {
            enabledDebrids.insert(.premiumize)
            UserDefaults.standard.set(false, forKey: "Premiumize.Enabled")
        }
    }

    // Cleans all cached IA values in the event of a full IA refresh
    public func clearIAValues() {
        realDebridIAValues = []
        allDebridIAValues = []
        premiumizeIAValues = []
    }

    // Clears all selected files and items
    public func clearSelectedDebridItems() {
        switch selectedDebridType {
        case .realDebrid:
            selectedRealDebridFile = nil
            selectedRealDebridItem = nil
        case .allDebrid:
            selectedAllDebridFile = nil
            selectedAllDebridItem = nil
        case .premiumize:
            selectedPremiumizeFile = nil
            selectedPremiumizeItem = nil
        case .none:
            break
        }
    }

    // Common function to populate hashes for debrid services
    public func populateDebridIA(_ resultMagnets: [Magnet]) async {
        do {
            let now = Date()

            // If a hash isn't found in the IA, update it
            // If the hash is expired, remove it and update it
            let sendMagnets = resultMagnets.filter { magnet in
                if let IAIndex = realDebridIAValues.firstIndex(where: { $0.magnet.hash == magnet.hash }), enabledDebrids.contains(.realDebrid) {
                    if now.timeIntervalSince1970 > realDebridIAValues[IAIndex].expiryTimeStamp {
                        realDebridIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else if let IAIndex = allDebridIAValues.firstIndex(where: { $0.magnet.hash == magnet.hash }), enabledDebrids.contains(.allDebrid) {
                    if now.timeIntervalSince1970 > allDebridIAValues[IAIndex].expiryTimeStamp {
                        allDebridIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else if let IAIndex = premiumizeIAValues.firstIndex(where: { $0.magnet.hash == magnet.hash }), enabledDebrids.contains(.premiumize) {
                    if now.timeIntervalSince1970 > premiumizeIAValues[IAIndex].expiryTimeStamp {
                        premiumizeIAValues.remove(at: IAIndex)
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }

            if !sendMagnets.isEmpty {
                if enabledDebrids.contains(.realDebrid) {
                    let fetchedRealDebridIA = try await realDebrid.instantAvailability(magnets: sendMagnets)
                    realDebridIAValues += fetchedRealDebridIA
                }

                if enabledDebrids.contains(.allDebrid) {
                    let fetchedAllDebridIA = try await allDebrid.instantAvailability(magnets: sendMagnets)
                    allDebridIAValues += fetchedAllDebridIA
                }

                if enabledDebrids.contains(.premiumize) {
                    // Only strip magnets that don't have an associated link for PM
                    let strippedResultMagnets: [Magnet] = resultMagnets.compactMap {
                        if let magnetLink = $0.link {
                            return Magnet(hash: $0.hash, link: magnetLink)
                        } else {
                            return nil
                        }
                    }

                    let availableMagnets = try await premiumize.divideCacheRequests(magnets: strippedResultMagnets)

                    // Split DDL requests into chunks of 10
                    for chunk in availableMagnets.chunked(into: 10) {
                        let tempIA = try await premiumize.divideDDLRequests(magnetChunk: chunk)

                        premiumizeIAValues += tempIA
                    }
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

    // Common function to match a magnet hash with a provided debrid service
    public func matchMagnetHash(_ magnet: Magnet) -> IAStatus {
        guard let magnetHash = magnet.hash else {
            return .none
        }

        switch selectedDebridType {
        case .realDebrid:
            guard let realDebridMatch = realDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) else {
                return .none
            }

            if realDebridMatch.batches.isEmpty {
                return .full
            } else {
                return .partial
            }
        case .allDebrid:
            guard let allDebridMatch = allDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) else {
                return .none
            }

            if allDebridMatch.files.count > 1 {
                return .partial
            } else {
                return .full
            }
        case .premiumize:
            guard let premiumizeMatch = premiumizeIAValues.first(where: { magnetHash == $0.magnet.hash }) else {
                return .none
            }

            if premiumizeMatch.files.count > 1 {
                return .partial
            } else {
                return .full
            }
        case .none:
            return .none
        }
    }

    public func selectDebridResult(magnet: Magnet) -> Bool {
        guard let magnetHash = magnet.hash else {
            toastModel?.updateToastDescription("Could not find the torrent magnet hash")
            return false
        }

        switch selectedDebridType {
        case .realDebrid:
            if let realDebridItem = realDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedRealDebridItem = realDebridItem
                return true
            } else {
                toastModel?.updateToastDescription("Could not find the associated RealDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .allDebrid:
            if let allDebridItem = allDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedAllDebridItem = allDebridItem
                return true
            } else {
                toastModel?.updateToastDescription("Could not find the associated AllDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .premiumize:
            if let premiumizeItem = premiumizeIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedPremiumizeItem = premiumizeItem
                return true
            } else {
                toastModel?.updateToastDescription("Could not find the associated Premiumize entry for magnet hash \(magnetHash)")
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
            let success = await authenticateRd()
            completeDebridAuth(debridType, success: success)
        case .allDebrid:
            let success = await authenticateAd()
            completeDebridAuth(debridType, success: success)
        case .premiumize:
            await authenticatePm()
        }
    }

    // Callback to finish debrid auth since functions can be split
    func completeDebridAuth(_ debridType: DebridType, success: Bool = true) {
        if enabledDebrids.count == 1, success {
            print("Enabled debrids is 1!")
            selectedDebridType = enabledDebrids.first
        }

        switch debridType {
        case .realDebrid:
            realDebridAuthProcessing = false
        case .allDebrid:
            allDebridAuthProcessing = false
        case .premiumize:
            premiumizeAuthProcessing = false
        }
    }

    // Wrapper function to validate and present an auth URL to the user
    @discardableResult func validateAuthUrl(_ url: URL?, useAuthSession: Bool = false) -> Bool {
        guard let url else {
            toastModel?.updateToastDescription("Authentication Error: Invalid URL created: \(String(describing: url))")
            return false
        }

        authUrl = url
        if useAuthSession {
            showAuthSession.toggle()
        } else {
            showWebView.toggle()
        }

        return true
    }

    private func authenticateRd() async -> Bool {
        do {
            realDebridAuthProcessing = true
            let verificationResponse = try await realDebrid.getVerificationInfo()

            if validateAuthUrl(URL(string: verificationResponse.directVerificationURL)) {
                try await realDebrid.getDeviceCredentials(deviceCode: verificationResponse.deviceCode)
                enabledDebrids.insert(.realDebrid)
            } else {
                throw RealDebrid.RDError.AuthQuery(description: "The verification URL was invalid")
            }

            return true
        } catch {
            toastModel?.updateToastDescription("RealDebrid authentication error: \(error)")
            realDebrid.authTask?.cancel()

            print("RealDebrid authentication error: \(error)")

            return false
        }
    }

    private func authenticateAd() async -> Bool {
        do {
            allDebridAuthProcessing = true
            let pinResponse = try await allDebrid.getPinInfo()

            if validateAuthUrl(URL(string: pinResponse.userURL)) {
                try await allDebrid.getApiKey(checkID: pinResponse.check, pin: pinResponse.pin)
                enabledDebrids.insert(.allDebrid)
            } else {
                throw AllDebrid.ADError.AuthQuery(description: "The PIN URL was invalid")
            }

            return true
        } catch {
            toastModel?.updateToastDescription("AllDebrid authentication error: \(error)")
            allDebrid.authTask?.cancel()

            print("AllDebrid authentication error: \(error)")

            return false
        }
    }

    private func authenticatePm() async {
        do {
            premiumizeAuthProcessing = true
            let tempAuthUrl = try premiumize.buildAuthUrl()

            validateAuthUrl(tempAuthUrl, useAuthSession: true)
        } catch {
            toastModel?.updateToastDescription("Premiumize authentication error: \(error)")
            completeDebridAuth(.premiumize, success: false)

            print("Premiumize authentication error (auth): \(error)")
        }
    }

    // Currently handles Premiumize callback
    public func handleCallback(url: URL?, error: Error?) {
        do {
            if let error {
                throw Premiumize.PMError.AuthQuery(description: "OAuth callback Error: \(error)")
            }

            if let callbackUrl = url {
                try premiumize.handleAuthCallback(url: callbackUrl)
                enabledDebrids.insert(.premiumize)
                completeDebridAuth(.premiumize)
            } else {
                throw Premiumize.PMError.AuthQuery(description: "The callback URL was invalid")
            }
        } catch {
            toastModel?.updateToastDescription("Premiumize authentication error: \(error)")
            completeDebridAuth(.premiumize, success: false)

            print("Premiumize authentication error (callback): \(error)")
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
        case .premiumize:
            logoutPm()
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
        } catch {
            toastModel?.updateToastDescription("RealDebrid logout error: \(error)")

            print("RealDebrid logout error: \(error)")
        }
    }

    private func logoutAd() {
        allDebrid.deleteTokens()
        enabledDebrids.remove(.allDebrid)

        toastModel?.updateToastDescription("Please manually delete the AllDebrid API key", newToastType: .info)
    }

    private func logoutPm() {
        premiumize.deleteTokens()
        enabledDebrids.remove(.premiumize)
    }

    // MARK: - Debrid fetch UI linked functions

    // Common function to delegate what debrid service to fetch from
    public func fetchDebridDownload(magnet: Magnet?) async {
        defer {
            currentDebridTask = nil
            showLoadingProgress = false
        }

        showLoadingProgress = true

        switch selectedDebridType {
        case .realDebrid:
            await fetchRdDownload(magnet: magnet)
        case .allDebrid:
            await fetchAdDownload(magnet: magnet)
        case .premiumize:
            await fetchPmDownload()
        case .none:
            break
        }
    }

    func fetchRdDownload(magnet: Magnet?) async {
        do {
            // Bypass the TTL since a download needs to be queried
            await fetchRdCloud(bypassTTL: true)

            // If there's an existing torrent, check for a download link. Otherwise check for an unrestrict link
            let existingTorrents = realDebridCloudTorrents.filter { $0.hash == selectedRealDebridItem?.magnet.hash && $0.status == "downloaded" }

            // If the links match from a user's downloads, no need to re-run a download
            if let existingTorrent = existingTorrents[safe: 0],
               let torrentLink = existingTorrent.links[safe: selectedRealDebridFile?.batchFileIndex ?? 0]
            {
                try await checkRdUserDownloads(userTorrentLink: torrentLink)
            } else if let magnet {
                // Add a magnet after all the cache checks fail
                selectedRealDebridID = try await realDebrid.addMagnet(magnet: magnet)

                var fileIds: [Int] = []
                if let iaFile = selectedRealDebridFile {
                    guard let iaBatchFromFile = selectedRealDebridItem?.batches[safe: iaFile.batchIndex] else {
                        return
                    }

                    fileIds = iaBatchFromFile.files.map(\.id)
                }

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
            } else {
                toastModel?.updateToastDescription("Could not fetch your file from RealDebrid's cache or API")
                print("RealDebrid error: No magnet link or cached file found")
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

                await deleteRdTorrent(torrentID: selectedRealDebridID)
            }

            showLoadingProgress = false

            print("RealDebrid download error: \(error)")
        }
    }

    // Refreshes torrents and downloads from a RD user's account
    public func fetchRdCloud(bypassTTL: Bool = false) async {
        if bypassTTL || Date().timeIntervalSince1970 > realDebridCloudTTL {
            do {
                realDebridCloudTorrents = try await realDebrid.userTorrents()
                realDebridCloudDownloads = try await realDebrid.userDownloads()

                // 5 minutes
                realDebridCloudTTL = Date().timeIntervalSince1970 + 300
            } catch {
                toastModel?.updateToastDescription("RealDebrid cloud fetch error: \(error)")
                print("RealDebrid cloud fetch error: \(error)")
            }
        }
    }

    func deleteRdDownload(downloadID: String) async {
        do {
            try await realDebrid.deleteDownload(debridID: downloadID)

            // Bypass TTL to get current RD values
            await fetchRdCloud(bypassTTL: true)
        } catch {
            toastModel?.updateToastDescription("RealDebrid download delete error: \(error)")
            print("RealDebrid download delete error: \(error)")
        }
    }

    func deleteRdTorrent(torrentID: String? = nil) async {
        do {
            if let torrentID = torrentID {
                try await realDebrid.deleteTorrent(debridID: torrentID)
            } else if let selectedTorrentID = selectedRealDebridID {
                try await realDebrid.deleteTorrent(debridID: selectedTorrentID)
            } else {
                throw RealDebrid.RDError.FailedRequest(description: "No torrent ID was provided")
            }
        } catch {
            toastModel?.updateToastDescription("RealDebrid torrent delete error: \(error)")
            print("RealDebrid torrent delete error: \(error)")
        }
    }

    func checkRdUserDownloads(userTorrentLink: String) async throws {
        let existingLinks = realDebridCloudDownloads.filter { $0.link == userTorrentLink }
        if let existingLink = existingLinks[safe: 0]?.download {
            downloadUrl = existingLink
        } else {
            let downloadLink = try await realDebrid.unrestrictLink(debridDownloadLink: userTorrentLink)

            downloadUrl = downloadLink
        }
    }

    func fetchAdDownload(magnet: Magnet?) async {
        guard let magnet else {
            toastModel?.updateToastDescription("Could not run your action because the magnet is invalid.")
            print("AllDebrid error: Invalid magnet")

            return
        }

        do {
            let magnetID = try await allDebrid.addMagnet(magnet: magnet)
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

    func fetchPmDownload(cloudItemId: String? = nil) async {
        do {
            if let cloudItemId = cloudItemId {
                downloadUrl = try await premiumize.itemDetails(itemID: cloudItemId).link
            } else if let premiumizeFile = selectedPremiumizeFile {
                downloadUrl = premiumizeFile.streamUrlString
            } else if
                let premiumizeItem = selectedPremiumizeItem,
                let firstFile = premiumizeItem.files[safe: 0]
            {
                downloadUrl = firstFile.streamUrlString
            } else {
                throw Premiumize.PMError.FailedRequest(description: "There were no items or files found!")
            }

            // Add a PM transfer if the item exists
            if let premiumizeItem = selectedPremiumizeItem {
                try await premiumize.createTransfer(magnet: premiumizeItem.magnet)
            }
        } catch {
            toastModel?.updateToastDescription("Premiumize download error: \(error)")
            print("Premiumize download error: \(error)")
        }
    }

    // Refreshes items and fetches from a PM user account
    public func fetchPmCloud(bypassTTL: Bool = false) async {
        if bypassTTL || Date().timeIntervalSince1970 > premiumizeCloudTTL {
            do {
                let userItems = try await premiumize.userItems()
                withAnimation {
                    premiumizeCloudItems = userItems
                }

                // 5 minutes
                premiumizeCloudTTL = Date().timeIntervalSince1970 + 300
            } catch {
                toastModel?.updateToastDescription("Premiumize cloud fetch error: \(error)")
                print("Premiumize cloud fetch error: \(error)")
            }
        }
    }

    public func deletePmItem(id: String) async {
        do {
            try await premiumize.deleteItem(itemID: id)

            // Bypass TTL to get current RD values
            await fetchPmCloud(bypassTTL: true)
        } catch {
            toastModel?.updateToastDescription("Premiumize cloud delete error: \(error)")
            print("Premiumize cloud delete error: \(error)")
        }
    }
}

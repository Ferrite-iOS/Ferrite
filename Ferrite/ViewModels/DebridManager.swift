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
    var logManager: LoggingManager?
    let realDebrid: RealDebrid = .init()
    let allDebrid: AllDebrid = .init()
    let premiumize: Premiumize = .init()

    // UI Variables
    @Published var showWebView: Bool = false
    @Published var showAuthSession: Bool = false

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

    @Published var filteredIAStatus: Set<IAStatus> = []

    var currentDebridTask: Task<Void, Never>?
    var downloadUrl: String = ""
    var authUrl: URL?

    // Is the current debrid type processing an auth request
    func authProcessing(_ passedDebridType: DebridType?) -> Bool {
        guard let debridType = passedDebridType ?? selectedDebridType else {
            return false
        }

        switch debridType {
        case .realDebrid:
            return realDebridAuthProcessing
        case .allDebrid:
            return allDebridAuthProcessing
        case .premiumize:
            return premiumizeAuthProcessing
        }
    }

    // RealDebrid auth variables
    var realDebridAuthProcessing: Bool = false

    // RealDebrid fetch variables
    @Published var realDebridIAValues: [RealDebrid.IA] = []

    @Published var showDeleteAlert: Bool = false

    var selectedRealDebridItem: RealDebrid.IA?
    var selectedRealDebridFile: RealDebrid.IAFile?
    var selectedRealDebridID: String?

    // TODO: Maybe make these generic?
    // RealDebrid cloud variables
    @Published var realDebridCloudTorrents: [RealDebrid.UserTorrentsResponse] = []
    @Published var realDebridCloudDownloads: [RealDebrid.UserDownloadsResponse] = []
    var realDebridCloudTTL: Double = 0.0

    // AllDebrid auth variables
    var allDebridAuthProcessing: Bool = false

    // AllDebrid fetch variables
    @Published var allDebridIAValues: [AllDebrid.IA] = []

    var selectedAllDebridItem: AllDebrid.IA?
    var selectedAllDebridFile: AllDebrid.IAFile?

    // AllDebrid cloud variables
    @Published var allDebridCloudMagnets: [AllDebrid.MagnetStatusData] = []
    @Published var allDebridCloudLinks: [AllDebrid.SavedLink] = []
    var allDebridCloudTTL: Double = 0.0

    // Premiumize auth variables
    var premiumizeAuthProcessing: Bool = false

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

    // Wrapper function to match error descriptions
    // Error can be suppressed to end user but must be printed in logs
    func sendDebridError(
        _ error: Error,
        prefix: String,
        presentError: Bool = true,
        cancelString: String? = nil
    ) async {
        let error = error as NSError
        if presentError {
            switch error.code {
            case -1009:
                logManager?.info(
                    "DebridManager: The connection is offline",
                    description: "The connection is offline"
                )
            case -999:
                if let cancelString {
                    logManager?.info(cancelString, description: cancelString)
                } else {
                    break
                }
            default:
                logManager?.error("\(prefix): \(error)")
            }
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

        // Don't exit the function if the API fetch errors
        if !sendMagnets.isEmpty {
            if enabledDebrids.contains(.realDebrid) {
                do {
                    let fetchedRealDebridIA = try await realDebrid.instantAvailability(magnets: sendMagnets)
                    realDebridIAValues += fetchedRealDebridIA
                } catch {
                    await sendDebridError(error, prefix: "RealDebrid IA fetch error")
                }
            }

            if enabledDebrids.contains(.allDebrid) {
                do {
                    let fetchedAllDebridIA = try await allDebrid.instantAvailability(magnets: sendMagnets)
                    allDebridIAValues += fetchedAllDebridIA
                } catch {
                    await sendDebridError(error, prefix: "AllDebrid IA fetch error")
                }
            }

            if enabledDebrids.contains(.premiumize) {
                do {
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
                } catch {
                    await sendDebridError(error, prefix: "Premiumize IA fetch error")
                }
            }
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
            logManager?.error("DebridManager: Could not find the torrent magnet hash")
            return false
        }

        switch selectedDebridType {
        case .realDebrid:
            if let realDebridItem = realDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedRealDebridItem = realDebridItem
                return true
            } else {
                logManager?.error("DebridManager: Could not find the associated RealDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .allDebrid:
            if let allDebridItem = allDebridIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedAllDebridItem = allDebridItem
                return true
            } else {
                logManager?.error("DebridManager: Could not find the associated AllDebrid entry for magnet hash \(magnetHash)")
                return false
            }
        case .premiumize:
            if let premiumizeItem = premiumizeIAValues.first(where: { magnetHash == $0.magnet.hash }) {
                selectedPremiumizeItem = premiumizeItem
                return true
            } else {
                logManager?.error("DebridManager: Could not find the associated Premiumize entry for magnet hash \(magnetHash)")
                return false
            }
        case .none:
            return false
        }
    }

    // MARK: - Authentication UI linked functions

    // Common function to delegate what debrid service to authenticate with
    public func authenticateDebrid(debridType: DebridType, apiKey: String?) async {
        switch debridType {
        case .realDebrid:
            let success = apiKey == nil ? await authenticateRd() : realDebrid.setApiKey(apiKey!)
            completeDebridAuth(debridType, success: success)
        case .allDebrid:
            // Async can't work with nil mapping method
            let success = apiKey == nil ? await authenticateAd() : allDebrid.setApiKey(apiKey!)
            completeDebridAuth(debridType, success: success)
        case .premiumize:
            if let apiKey {
                let success = premiumize.setApiKey(apiKey)
                completeDebridAuth(debridType, success: success)
            } else {
                await authenticatePm()
            }
        }
    }

    // Callback to finish debrid auth since functions can be split
    func completeDebridAuth(_ debridType: DebridType, success: Bool) {
        if success {
            enabledDebrids.insert(debridType)
            if enabledDebrids.count == 1 {
                selectedDebridType = enabledDebrids.first
            }
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

    // Get a truncated manual API key if it's being used
    func getManualAuthKey(_ passedDebridType: DebridType?) async -> String? {
        guard let debridType = passedDebridType ?? selectedDebridType else {
            return nil
        }

        let debridToken: String?
        switch debridType {
        case .realDebrid:
            if UserDefaults.standard.bool(forKey: "RealDebrid.UseManualKey") {
                debridToken = FerriteKeychain.shared.get("RealDebrid.AccessToken")
            } else {
                debridToken = nil
            }
        case .allDebrid:
            if UserDefaults.standard.bool(forKey: "AllDebrid.UseManualKey") {
                debridToken = FerriteKeychain.shared.get("AllDebrid.ApiKey")
            } else {
                debridToken = nil
            }
        case .premiumize:
            if UserDefaults.standard.bool(forKey: "Premiumize.UseManualKey") {
                debridToken = FerriteKeychain.shared.get("Premiumize.AccessToken")
            } else {
                debridToken = nil
            }
        }

        if let debridToken {
            let splitString = debridToken.suffix(4)

            if debridToken.count > 4 {
                return String(repeating: "*", count: debridToken.count - 4) + splitString
            } else {
                return String(splitString)
            }
        } else {
            return nil
        }
    }

    // Wrapper function to validate and present an auth URL to the user
    @discardableResult func validateAuthUrl(_ url: URL?, useAuthSession: Bool = false) -> Bool {
        guard let url else {
            logManager?.error("DebridManager: Authentication: Invalid URL created: \(String(describing: url))")
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
                return true
            } else {
                throw RealDebrid.RDError.AuthQuery(description: "The verification URL was invalid")
            }
        } catch {
            await sendDebridError(error, prefix: "RealDebrid authentication error")

            realDebrid.authTask?.cancel()
            return false
        }
    }

    private func authenticateAd() async -> Bool {
        do {
            allDebridAuthProcessing = true
            let pinResponse = try await allDebrid.getPinInfo()

            if validateAuthUrl(URL(string: pinResponse.userURL)) {
                try await allDebrid.getApiKey(checkID: pinResponse.check, pin: pinResponse.pin)
                return true
            } else {
                throw AllDebrid.ADError.AuthQuery(description: "The PIN URL was invalid")
            }
        } catch {
            await sendDebridError(error, prefix: "AllDebrid authentication error")

            allDebrid.authTask?.cancel()
            return false
        }
    }

    private func authenticatePm() async {
        do {
            premiumizeAuthProcessing = true
            let tempAuthUrl = try premiumize.buildAuthUrl()

            validateAuthUrl(tempAuthUrl, useAuthSession: true)
        } catch {
            await sendDebridError(error, prefix: "Premiumize authentication error")

            completeDebridAuth(.premiumize, success: false)
        }
    }

    // Currently handles Premiumize callback
    public func handleCallback(url: URL?, error: Error?) async {
        do {
            if let error {
                throw Premiumize.PMError.AuthQuery(description: "OAuth callback Error: \(error)")
            }

            if let callbackUrl = url {
                try premiumize.handleAuthCallback(url: callbackUrl)
                completeDebridAuth(.premiumize, success: true)
            } else {
                throw Premiumize.PMError.AuthQuery(description: "The callback URL was invalid")
            }
        } catch {
            await sendDebridError(error, prefix: "Premiumize authentication error (callback)")

            completeDebridAuth(.premiumize, success: false)
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
            await sendDebridError(error, prefix: "RealDebrid logout error")
        }
    }

    private func logoutAd() {
        allDebrid.deleteTokens()
        enabledDebrids.remove(.allDebrid)

        logManager?.info(
            "AllDebrid: Logged out, API key needs to be removed",
            description: "Please manually delete the AllDebrid API key"
        )
    }

    private func logoutPm() {
        premiumize.deleteTokens()
        enabledDebrids.remove(.premiumize)
    }

    // MARK: - Debrid fetch UI linked functions

    // Common function to delegate what debrid service to fetch from
    // Cloudinfo is used for any extra information provided by debrid cloud
    public func fetchDebridDownload(magnet: Magnet?, cloudInfo: String? = nil) async {
        defer {
            currentDebridTask = nil
            logManager?.hideIndeterminateToast()
        }

        logManager?.updateIndeterminateToast("Loading content", cancelAction: {
            self.currentDebridTask?.cancel()
            self.currentDebridTask = nil
        })

        switch selectedDebridType {
        case .realDebrid:
            await fetchRdDownload(magnet: magnet, existingLink: cloudInfo)
        case .allDebrid:
            await fetchAdDownload(magnet: magnet, existingLockedLink: cloudInfo)
        case .premiumize:
            await fetchPmDownload(cloudItemId: cloudInfo)
        case .none:
            break
        }
    }

    func fetchRdDownload(magnet: Magnet?, existingLink: String?) async {
        // If an existing link is passed in args, set it to that. Otherwise, find one from RD cloud.
        let torrentLink: String?
        if let existingLink {
            torrentLink = existingLink
        } else {
            // Bypass the TTL for up to date information
            await fetchRdCloud(bypassTTL: true)

            let existingTorrent = realDebridCloudTorrents.first { $0.hash == selectedRealDebridItem?.magnet.hash && $0.status == "downloaded" }
            torrentLink = existingTorrent?.links[safe: selectedRealDebridFile?.batchFileIndex ?? 0]
        }

        do {
            // If the links match from a user's downloads, no need to re-run a download
            if let torrentLink,
               let downloadLink = await checkRdUserDownloads(userTorrentLink: torrentLink)
            {
                downloadUrl = downloadLink
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
                    logManager?.error(
                        "RealDebrid: Could not cache torrent with hash \(String(describing: magnet.hash))",
                        description: "Could not cache this torrent. Aborting."
                    )
                }
            } else {
                throw RealDebrid.RDError.FailedRequest(description: "Could not fetch your file from RealDebrid's cache or API")
            }

            // Fetch one more time to add updated data into the RD cloud cache
            await fetchRdCloud(bypassTTL: true)
        } catch {
            switch error {
            case RealDebrid.RDError.EmptyTorrents:
                showDeleteAlert.toggle()
            default:
                await sendDebridError(error, prefix: "RealDebrid download error", cancelString: "Download cancelled")

                await deleteRdTorrent(torrentID: selectedRealDebridID, presentError: false)
            }

            logManager?.hideIndeterminateToast()
        }
    }

    public func fetchDebridCloud(bypassTTL: Bool = false) async {
        switch selectedDebridType {
        case .realDebrid:
            await fetchRdCloud(bypassTTL: bypassTTL)
        case .allDebrid:
            await fetchAdCloud(bypassTTL: bypassTTL)
        case .premiumize:
            await fetchPmCloud(bypassTTL: bypassTTL)
        case .none:
            return
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
                await sendDebridError(error, prefix: "RealDebrid cloud fetch error")
            }
        }
    }

    func deleteRdDownload(downloadID: String) async {
        do {
            try await realDebrid.deleteDownload(debridID: downloadID)

            // Bypass TTL to get current RD values
            await fetchRdCloud(bypassTTL: true)
        } catch {
            await sendDebridError(error, prefix: "RealDebrid download delete error")
        }
    }

    func deleteRdTorrent(torrentID: String? = nil, presentError: Bool = true) async {
        do {
            if let torrentID {
                try await realDebrid.deleteTorrent(debridID: torrentID)
            } else if let selectedTorrentID = selectedRealDebridID {
                try await realDebrid.deleteTorrent(debridID: selectedTorrentID)
            } else {
                throw RealDebrid.RDError.FailedRequest(description: "No torrent ID was provided")
            }
        } catch {
            await sendDebridError(error, prefix: "RealDebrid torrent delete error", presentError: presentError)
        }
    }

    func checkRdUserDownloads(userTorrentLink: String) async -> String? {
        do {
            let existingLinks = realDebridCloudDownloads.first { $0.link == userTorrentLink }
            if let existingLink = existingLinks?.download {
                return existingLink
            } else {
                return try await realDebrid.unrestrictLink(debridDownloadLink: userTorrentLink)
            }
        } catch {
            await sendDebridError(error, prefix: "RealDebrid download check error")

            return nil
        }
    }

    // TODO: Integrate with AD saved links
    func fetchAdDownload(magnet: Magnet?, existingLockedLink: String?) async {
        // If an existing link is passed in args, set it to that. Otherwise, find one from AD cloud.
        let lockedLink: String?
        if let existingLockedLink {
            lockedLink = existingLockedLink
        } else {
            // Bypass the TTL for up to date information
            await fetchAdCloud(bypassTTL: true)

            let existingMagnet = allDebridCloudMagnets.first { $0.hash == selectedAllDebridItem?.magnet.hash && $0.status == "Ready" }
            lockedLink = existingMagnet?.links[safe: selectedAllDebridFile?.id ?? 0]?.link
        }

        do {
            if let lockedLink,
               let unlockedLink = await checkAdUserLinks(lockedLink: lockedLink)
            {
                downloadUrl = unlockedLink
            } else if let magnet {
                let magnetID = try await allDebrid.addMagnet(magnet: magnet)
                let lockedLink = try await allDebrid.fetchMagnetStatus(
                    magnetId: magnetID,
                    selectedIndex: selectedAllDebridFile?.id ?? 0
                )

                try await allDebrid.saveLink(link: lockedLink)
                downloadUrl = try await allDebrid.unlockLink(lockedLink: lockedLink)
            } else {
                throw AllDebrid.ADError.FailedRequest(description: "Could not fetch your file from AllDebrid's cache or API")
            }

            // Fetch one more time to add updated data into the AD cloud cache
            await fetchAdCloud(bypassTTL: true)
        } catch {
            await sendDebridError(error, prefix: "AllDebrid download error", cancelString: "Download cancelled")
        }
    }

    func checkAdUserLinks(lockedLink: String) async -> String? {
        do {
            let existingLinks = allDebridCloudLinks.first { $0.link == lockedLink }
            if let existingLink = existingLinks?.link {
                return existingLink
            } else {
                try await allDebrid.saveLink(link: lockedLink)
                return try await allDebrid.unlockLink(lockedLink: lockedLink)
            }
        } catch {
            await sendDebridError(error, prefix: "AllDebrid download check error")

            return nil
        }
    }

    // Refreshes torrents and downloads from a RD user's account
    public func fetchAdCloud(bypassTTL: Bool = false) async {
        if bypassTTL || Date().timeIntervalSince1970 > allDebridCloudTTL {
            do {
                allDebridCloudMagnets = try await allDebrid.userMagnets()
                allDebridCloudLinks = try await allDebrid.savedLinks()

                // 5 minutes
                allDebridCloudTTL = Date().timeIntervalSince1970 + 300
            } catch {
                await sendDebridError(error, prefix: "AlLDebrid cloud fetch error")
            }
        }
    }

    func deleteAdLink(link: String) async {
        do {
            try await allDebrid.deleteLink(link: link)

            await fetchAdCloud(bypassTTL: true)
        } catch {
            await sendDebridError(error, prefix: "AllDebrid link delete error")
        }
    }

    func deleteAdMagnet(magnetId: Int) async {
        do {
            try await allDebrid.deleteMagnet(magnetId: magnetId)

            await fetchAdCloud(bypassTTL: true)
        } catch {
            await sendDebridError(error, prefix: "AllDebrid magnet delete error")
        }
    }

    func fetchPmDownload(cloudItemId: String? = nil) async {
        do {
            if let cloudItemId {
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

            // Fetch one more time to add updated data into the PM cloud cache
            await fetchPmCloud(bypassTTL: true)

            // Add a PM transfer if the item exists
            if let premiumizeItem = selectedPremiumizeItem {
                try await premiumize.createTransfer(magnet: premiumizeItem.magnet)
            }
        } catch {
            await sendDebridError(error, prefix: "Premiumize download error", cancelString: "Download or transfer cancelled")
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
                let error = error as NSError
                if error.code != -999 {
                    await sendDebridError(error, prefix: "Premiumize cloud fetch error")
                }
            }
        }
    }

    public func deletePmItem(id: String) async {
        do {
            try await premiumize.deleteItem(itemID: id)

            // Bypass TTL to get current RD values
            await fetchPmCloud(bypassTTL: true)
        } catch {
            await sendDebridError(error, prefix: "Premiumize cloud delete error")
        }
    }
}

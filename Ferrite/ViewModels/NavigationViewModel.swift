//
//  NavigationViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

enum ViewTab {
    case search
    case sources
    case settings
    case library
}

@MainActor
class NavigationViewModel: ObservableObject {
    var toastModel: ToastViewModel?

    // Used between SearchResultsView and MagnetChoiceView
    enum ChoiceSheetType: Identifiable {
        var id: Int {
            hashValue
        }

        case magnet
        case batch
        case activity
    }

    @Published var isEditingSearch: Bool = false
    @Published var isSearching: Bool = false

    @Published var selectedSearchResult: SearchResult?

    // For giving information in magnet choice sheet
    @Published var selectedTitle: String = ""
    @Published var selectedBatchTitle: String = ""

    @Published var hideNavigationBar = false

    @Published var currentChoiceSheet: ChoiceSheetType?
    var activityItems: [Any] = []

    // Used to show the activity sheet in the share menu
    @Published var showLocalActivitySheet = false

    @Published var selectedTab: ViewTab = .search
    @Published var showSearchProgress: Bool = false

    // Used between SourceListView and SourceSettingsView
    @Published var showSourceSettings: Bool = false
    var selectedSource: Source?

    @Published var showSourceListEditor: Bool = false
    var selectedSourceList: SourceList?

    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    public func runDebridAction(urlString: String, _ action: DefaultDebridActionType? = nil) {
        let selectedAction = action ?? defaultDebridAction

        switch selectedAction {
        case .none:
            currentChoiceSheet = .magnet
        case .outplayer:
            if let downloadUrl = URL(string: "outplayer://\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.updateToastDescription("Could not create an Outplayer URL")
            }
        case .vlc:
            if let downloadUrl = URL(string: "vlc://\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.updateToastDescription("Could not create a VLC URL")
            }
        case .infuse:
            if let downloadUrl = URL(string: "infuse://x-callback-url/play?url=\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.updateToastDescription("Could not create a Infuse URL")
            }
        case .shareDownload:
            if let downloadUrl = URL(string: urlString), currentChoiceSheet == nil {
                activityItems = [downloadUrl]
                currentChoiceSheet = .activity
            } else {
                toastModel?.updateToastDescription("Could not create object for sharing")
            }
        }
    }

    public func runMagnetAction(magnetString: String?, _ action: DefaultMagnetActionType? = nil) {
        let selectedAction = action ?? defaultMagnetAction

        guard let magnetLink = magnetString else {
            toastModel?.updateToastDescription("Could not run your action because the magnet link is invalid.")
            print("Magnet action error: The magnet link is invalid.")

            return
        }

        switch selectedAction {
        case .none:
            currentChoiceSheet = .magnet
        case .webtor:
            if let url = URL(string: "https://webtor.io/#/show?magnet=\(magnetLink)") {
                UIApplication.shared.open(url)
            } else {
                toastModel?.updateToastDescription("Could not create a WebTor URL")
            }
        case .shareMagnet:
            if let magnetUrl = URL(string: magnetLink),
               currentChoiceSheet == nil
            {
                activityItems = [magnetUrl]
                currentChoiceSheet = .activity
            } else {
                toastModel?.updateToastDescription("Could not create object for sharing")
            }
        }
    }

    public func addToHistory(name: String?, source: String?, url: String?, subName: String? = nil) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        // The timeStamp and date are nil because the create function will make them automatically
        PersistenceController.shared.createHistory(
            entryJson: HistoryEntryJson(
                name: name ?? "",
                subName: subName,
                url: url ?? "",
                timeStamp: nil,
                source: source
            ),
            date: nil
        )

        PersistenceController.shared.save(backgroundContext)
    }
}

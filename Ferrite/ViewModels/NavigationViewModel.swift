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
    }

    @Published var isEditingSearch: Bool = false
    @Published var isSearching: Bool = false

    @Published var hideNavigationBar = false

    @Published var currentChoiceSheet: ChoiceSheetType?
    @Published var activityItems: [Any] = []
    @Published var showActivityView: Bool = false

    @Published var selectedTab: ViewTab = .search
    @Published var showSearchProgress: Bool = false

    // Used between SourceListView and SourceSettingsView
    @Published var showSourceSettings: Bool = false
    @Published var selectedSource: Source?

    @Published var showSourceListEditor: Bool = false
    @Published var selectedSourceList: SourceList?

    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    public func runDebridAction(action: DefaultDebridActionType?, urlString: String) {
        let selectedAction = action ?? defaultDebridAction

        switch selectedAction {
        case .none:
            currentChoiceSheet = .magnet
        case .outplayer:
            if let downloadUrl = URL(string: "outplayer://\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.toastDescription = "Could not create an Outplayer URL"
            }
        case .vlc:
            if let downloadUrl = URL(string: "vlc://\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.toastDescription = "Could not create a VLC URL"
            }
        case .infuse:
            if let downloadUrl = URL(string: "infuse://x-callback-url/play?url=\(urlString)") {
                UIApplication.shared.open(downloadUrl)
            } else {
                toastModel?.toastDescription = "Could not create a Infuse URL"
            }
        case .shareDownload:
            if let downloadUrl = URL(string: urlString), currentChoiceSheet == nil {
                activityItems = [downloadUrl]
                showActivityView.toggle()
            } else {
                toastModel?.toastDescription = "Could not create object for sharing"
            }
        }
    }

    public func runMagnetAction(action: DefaultMagnetActionType?, searchResult: SearchResult) {
        let selectedAction = action ?? defaultMagnetAction

        switch selectedAction {
        case .none:
            currentChoiceSheet = .magnet
        case .webtor:
            if let url = URL(string: "https://webtor.io/#/show?magnet=\(searchResult.magnetLink)") {
                UIApplication.shared.open(url)
            } else {
                toastModel?.toastDescription = "Could not create a WebTor URL"
            }
        case .shareMagnet:
            if let magnetUrl = URL(string: searchResult.magnetLink), currentChoiceSheet == nil {
                activityItems = [magnetUrl]
                showActivityView.toggle()
            } else {
                toastModel?.toastDescription = "Could not create object for sharing"
            }
        }
    }
}

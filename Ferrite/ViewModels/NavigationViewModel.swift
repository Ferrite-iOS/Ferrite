//
//  NavigationViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

@MainActor
public class NavigationViewModel: ObservableObject {
    var logManager: LoggingManager?

    // Used between SearchResultsView and MagnetChoiceView
    public enum ChoiceSheetType: Identifiable {
        public var id: Int {
            hashValue
        }

        case action
        case batch
        case activity
    }

    enum ViewTab {
        case search
        case plugins
        case settings
        case library
    }

    enum LibraryPickerSegment {
        case bookmarks
        case history
        case debridCloud
    }

    enum PluginPickerSegment {
        case sources
        case actions
    }

    @Published var selectedMagnet: Magnet?
    @Published var selectedHistoryInfo: HistoryEntryJson?
    @Published var resultFromCloud: Bool = false

    // For giving information in magnet choice sheet
    @Published var selectedTitle: String = ""
    @Published var selectedBatchTitle: String = ""

    @Published var kodiExpanded: Bool = false

    @Published var currentChoiceSheet: ChoiceSheetType?
    var activityItems: [Any] = []

    // Used to show the activity sheet in the share menu
    @Published var showLocalActivitySheet = false

    @Published var selectedTab: ViewTab = .search

    // TODO: Maybe move these to their own StateObjects?
    // Used between SourceListView and SourceSettingsView
    @Published var showSourceSettings: Bool = false
    var selectedSource: Source?

    // Used between service views and editor views in Settings
    @Published var selectedPluginList: PluginList?
    @Published var selectedKodiServer: KodiServer?

    @Published var libraryPickerSelection: LibraryPickerSegment = .bookmarks
    @Published var pluginPickerSelection: PluginPickerSegment = .sources
}

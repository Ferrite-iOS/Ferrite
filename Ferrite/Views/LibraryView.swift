//
//  LibraryView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel

    @FetchRequest(
        entity: Bookmark.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.orderNum, ascending: true)]
    ) var bookmarks: FetchedResults<Bookmark>

    @FetchRequest(
        entity: HistoryEntry.entity(),
        sortDescriptors: []
    ) var allHistoryEntries: FetchedResults<HistoryEntry>

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @State private var editMode: EditMode = .inactive

    // Bound to the isSearching environment var
    @State private var isSearching = false
    @State private var searchText: String = ""

    var body: some View {
        NavView {
            ZStack {
                switch navModel.libraryPickerSelection {
                case .bookmarks:
                    BookmarksView(searchText: $searchText, bookmarks: bookmarks)
                case .history:
                    HistoryView(allHistoryEntries: allHistoryEntries, searchText: $searchText)
                case .debridCloud:
                    DebridCloudView(searchText: $searchText)
                }
            }
            .overlay {
                if !isSearching {
                    switch navModel.libraryPickerSelection {
                    case .bookmarks:
                        if bookmarks.isEmpty {
                            EmptyInstructionView(title: "No Bookmarks", message: "Add a bookmark from search results")
                        }
                    case .history:
                        if allHistoryEntries.isEmpty {
                            EmptyInstructionView(title: "No History", message: "Start watching to build history")
                        }
                    case .debridCloud:
                        if debridManager.selectedDebridType == nil {
                            EmptyInstructionView(title: "Cloud Unavailable", message: "Listing is not available for this service")
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Spacer()
                        EditButton()

                        switch navModel.libraryPickerSelection {
                        case .bookmarks, .debridCloud:
                            SelectedDebridFilterView {
                                Text(debridManager.selectedDebridType?.toString(abbreviated: true) ?? "Debrid")
                            }
                            .transaction {
                                $0.animation = .none
                            }
                        case .history:
                            HistoryActionsView()
                        }
                    }
                }
            }
            .expandedSearchable(
                text: $searchText,
                scopeBarContent: {
                    LibraryPickerView()
                }
            )
            .autocorrectionDisabled(!autocorrectSearch)
            .esAutocapitalization(autocorrectSearch ? .sentences : .none)
            .environment(\.editMode, $editMode)
        }
        .onChange(of: navModel.libraryPickerSelection) { _ in
            editMode = .inactive
        }
        .onDisappear {
            editMode = .inactive
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}

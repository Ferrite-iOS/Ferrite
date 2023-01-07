//
//  LibraryView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI
import SwiftUIX

struct LibraryView: View {
    enum LibraryPickerSegment {
        case bookmarks
        case history
        case debridCloud
    }

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    @FetchRequest(
        entity: Bookmark.entity(),
        sortDescriptors: []
    ) var bookmarks: FetchedResults<Bookmark>

    @FetchRequest(
        entity: History.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \History.date, ascending: false)
        ]
    ) var history: FetchedResults<History>

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @State private var selectedSegment: LibraryPickerSegment = .bookmarks
    @State private var editMode: EditMode = .inactive

    @State private var searchText: String = ""
    @State private var isEditingSearch = false
    @State private var isSearching = false

    var body: some View {
        NavView {
            VStack {
                Picker("Segments", selection: $selectedSegment) {
                    Text("Bookmarks").tag(LibraryPickerSegment.bookmarks)
                    Text("History").tag(LibraryPickerSegment.history)

                    if !debridManager.enabledDebrids.isEmpty {
                        Text("Cloud").tag(LibraryPickerSegment.debridCloud)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 5)

                switch selectedSegment {
                case .bookmarks:
                    BookmarksView(searchText: $searchText)
                case .history:
                    HistoryView(history: history, searchText: $searchText)
                case .debridCloud:
                    DebridCloudView(searchText: $searchText)
                }

                Spacer()
            }
            .navigationSearchBar {
                SearchBar("Search", text: $searchText, isEditing: $isEditingSearch, onCommit: {
                    isSearching = true
                })
                .showsCancelButton(isEditingSearch || isSearching)
                .onCancel {
                    searchText = ""
                    isSearching = false
                }
            }
            .introspectSearchController { searchController in
                searchController.searchBar.autocorrectionType = autocorrectSearch ? .default : .no
                searchController.searchBar.autocapitalizationType = autocorrectSearch ? .sentences : .none
            }
            .overlay {
                switch selectedSegment {
                case .bookmarks:
                    if bookmarks.isEmpty {
                        EmptyInstructionView(title: "No Bookmarks", message: "Add a bookmark from search results")
                    }
                case .history:
                    if history.isEmpty {
                        EmptyInstructionView(title: "No History", message: "Start watching to build history")
                    }
                case .debridCloud:
                    if debridManager.selectedDebridType == nil {
                        EmptyInstructionView(title: "Cloud Unavailable", message: "Listing is not available for this service")
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Application.shared.osVersion.majorVersion > 14 ? 10 : 18) {
                        Spacer()
                        EditButton()

                        switch selectedSegment {
                        case .bookmarks, .debridCloud:
                            DebridChoiceView()
                        case .history:
                            HistoryActionsView()
                        }
                    }
                    .animation(.none)
                }
            }
            .environment(\.editMode, $editMode)
        }
        .onChange(of: selectedSegment) { _ in
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

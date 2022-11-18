//
//  LibraryView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct LibraryView: View {
    enum LibraryPickerSegment {
        case bookmarks
        case history
    }

    @EnvironmentObject var navModel: NavigationViewModel

    @FetchRequest(
        entity: Bookmark.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Bookmark.orderNum, ascending: true)
        ]
    ) var bookmarks: FetchedResults<Bookmark>

    @FetchRequest(
        entity: History.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \History.date, ascending: false)
        ]
    ) var history: FetchedResults<History>

    @State private var historyEmpty = true

    @State private var selectedSegment: LibraryPickerSegment = .bookmarks
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavView {
            VStack {
                Picker("Segments", selection: $selectedSegment) {
                    Text("Bookmarks").tag(LibraryPickerSegment.bookmarks)
                    Text("History").tag(LibraryPickerSegment.history)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSegment {
                case .bookmarks:
                    BookmarksView(bookmarks: bookmarks)
                case .history:
                    HistoryView(history: history)
                }

                Spacer()
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
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()

                        if selectedSegment == .history {
                            HistoryActionsView()
                        }
                    }
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

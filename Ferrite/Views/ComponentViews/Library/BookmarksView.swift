//
//  BookmarksView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @Binding var searchText: String

    var bookmarks: FetchedResults<Bookmark>

    var body: some View {
        List {
            if !bookmarks.isEmpty {
                ForEach(bookmarks, id: \.self) { bookmark in
                    SearchResultButtonView(result: bookmark.toSearchResult(), existingBookmark: bookmark)
                }
                .onDelete { offsets in
                    for index in offsets {
                        if let bookmark = bookmarks[safe: index] {
                            PersistenceController.shared.delete(bookmark, context: backgroundContext)
                            NotificationCenter.default.post(name: .didDeleteBookmark, object: bookmark)
                        }
                    }
                }
                .onMove { source, destination in
                    var changedBookmarks = bookmarks.map { $0 }

                    changedBookmarks.move(fromOffsets: source, toOffset: destination)

                    for reverseIndex in stride(from: changedBookmarks.count - 1, through: 0, by: -1) {
                        changedBookmarks[reverseIndex].orderNum = Int16(reverseIndex)
                    }

                    PersistenceController.shared.save()
                }
            }
        }
        .onAppear {
            fetchPredicate()
        }
        .onChange(of: searchText) { _ in
            fetchPredicate()
        }
        .listStyle(.insetGrouped)
        .inlinedList(inset: 15)
        .task {
            if debridManager.enabledDebrids.count > 0 {
                let magnets = bookmarks.compactMap {
                    if let magnetHash = $0.magnetHash {
                        return Magnet(hash: magnetHash, link: $0.magnetLink)
                    } else {
                        return nil
                    }
                }
                await debridManager.populateDebridIA(magnets)
            }
        }
    }

    func fetchPredicate() {
        bookmarks.nsPredicate = searchText.isEmpty ? nil : NSPredicate(format: "title CONTAINS[cd] %@", searchText)
    }
}

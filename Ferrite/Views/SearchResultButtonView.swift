//
//  SearchResultButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

// BUG: iOS 15 cannot refresh the context menu. Debating using swipe actions or adopting a workaround.
struct SearchResultButtonView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    var result: SearchResult

    @State private var runOnce = false
    @State var existingBookmark: Bookmark? = nil

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                if debridManager.currentDebridTask == nil {
                    navModel.selectedSearchResult = result
                    
                    switch debridManager.matchSearchResult(result: result) {
                    case .full:
                        debridManager.currentDebridTask = Task {
                            await debridManager.fetchRdDownload(searchResult: result)
                            
                            if !debridManager.realDebridDownloadUrl.isEmpty {
                                navModel.runDebridAction(action: nil, urlString: debridManager.realDebridDownloadUrl)
                            }
                        }
                    case .partial:
                        if debridManager.setSelectedRdResult(result: result) {
                            navModel.currentChoiceSheet = .batch
                        }
                    case .none:
                        navModel.runMagnetAction()
                    }
                }
            } label: {
                Text(result.title ?? "No title")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .dynamicAccentColor(.primary)
            .padding(.bottom, 5)
            .conditionalContextMenu(id: existingBookmark) {
                if let bookmark = existingBookmark {
                    Button {
                        PersistenceController.shared.delete(bookmark, context: backgroundContext)

                        // When the entity is deleted, let other instances know to remove that reference
                        NotificationCenter.default.post(name: .didDeleteBookmark, object: nil)
                    } label: {
                        Text("Remove bookmark")
                        Image(systemName: "bookmark.slash.fill")
                    }
                } else {
                    Button {
                        let newBookmark = Bookmark(context: backgroundContext)
                        newBookmark.title = result.title
                        newBookmark.source = result.source
                        newBookmark.magnetHash = result.magnetHash
                        newBookmark.magnetLink = result.magnetLink
                        newBookmark.seeders = result.seeders
                        newBookmark.leechers = result.leechers
                        
                        existingBookmark = newBookmark
                        
                        PersistenceController.shared.save(backgroundContext)
                    } label: {
                        Text("Bookmark")
                        Image(systemName: "bookmark")
                    }
                }
            }
            
            SearchResultRDView(result: result)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didDeleteBookmark)) { _ in
            existingBookmark = nil
        }
        .onAppear {
            // Only run a exists request if a bookmark isn't passed to the view
            if existingBookmark == nil && !runOnce {
                let bookmarkRequest = Bookmark.fetchRequest()
                bookmarkRequest.predicate = NSPredicate(
                    format: "title == %@ AND source == %@ AND magnetLink == %@ AND magnetHash = %@",
                    result.title ?? "",
                    result.source,
                    result.magnetLink ?? "",
                    result.magnetHash ?? ""
                )
                bookmarkRequest.fetchLimit = 1

                if let fetchedBookmark = try? backgroundContext.fetch(bookmarkRequest).first {
                    existingBookmark = fetchedBookmark
                }

                runOnce = true
            }
        }
    }
}

//
//  SearchResultButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct SearchResultButtonView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var debridManager: DebridManager

    var result: SearchResult

    @State private var runOnce = false
    @State var existingBookmark: Bookmark? = nil
    @State private var showConfirmation = false

    var body: some View {
        Button {
            if debridManager.currentDebridTask == nil {
                navModel.selectedSearchResult = result
                navModel.selectedTitle = result.title ?? ""

                switch debridManager.matchSearchResult(result: result) {
                case .full:
                    if debridManager.selectDebridResult(result: result) {
                        debridManager.currentDebridTask = Task {
                            await debridManager.fetchDebridDownload(searchResult: result)

                            if !debridManager.downloadUrl.isEmpty {
                                navModel.addToHistory(name: result.title, source: result.source, url: debridManager.downloadUrl)
                                navModel.runDebridAction(urlString: debridManager.downloadUrl)

                                if navModel.currentChoiceSheet != .magnet {
                                    debridManager.downloadUrl = ""
                                }
                            }
                        }
                    }
                case .partial:
                    if debridManager.selectDebridResult(result: result) {
                        navModel.currentChoiceSheet = .batch
                    }
                case .none:
                    navModel.addToHistory(name: result.title, source: result.source, url: result.magnetLink)
                    navModel.runMagnetAction(magnetString: result.magnetLink)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(result.title ?? "No title")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)

                SearchResultInfoView(result: result)
            }
            .disabledAppearance(navModel.currentChoiceSheet != nil, dimmedOpacity: 0.7, animation: .easeOut(duration: 0.2))
        }
        .disableInteraction(navModel.currentChoiceSheet != nil)
        .backport.tint(.primary)
        .conditionalContextMenu(id: existingBookmark) {
            ZStack {
                if let bookmark = existingBookmark {
                    Button {
                        PersistenceController.shared.delete(bookmark, context: backgroundContext)

                        // When the entity is deleted, let other instances know to remove that reference
                        NotificationCenter.default.post(name: .didDeleteBookmark, object: existingBookmark)
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
        }
        .backport.alert(
            isPresented: $debridManager.showDeleteAlert,
            title: "Caching file",
            message: "RealDebrid is currently caching this file. Would you like to delete it? \n\nProgress can be checked on the RealDebrid website.",
            buttons: [
                AlertButton("Yes", role: .destructive) {
                    Task {
                        await debridManager.deleteRdTorrent()
                    }
                },
                AlertButton(role: .cancel)
            ]
        )
        .onReceive(NotificationCenter.default.publisher(for: .didDeleteBookmark)) { notification in
            // If the instance contains the deleted bookmark, remove it.
            if let deletedBookmark = notification.object as? Bookmark,
                let bookmark = existingBookmark,
                deletedBookmark.objectID == bookmark.objectID {
                existingBookmark = nil
            }
        }
        .onAppear {
            // Only run a exists request if a bookmark isn't passed to the view
            if existingBookmark == nil, !runOnce {
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

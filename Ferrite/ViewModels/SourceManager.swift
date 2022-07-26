//
//  SourceViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import Foundation

public class SourceManager: ObservableObject {
    var toastModel: ToastViewModel?

    @Published var availableSources: [TorrentSourceJson] = []

    @MainActor
    public func fetchSourcesFromUrl() async {
        let sourceUrlRequest = TorrentSourceUrl.fetchRequest()
        do {
            let sourceUrls = try PersistenceController.shared.backgroundContext.fetch(sourceUrlRequest)
            var tempSourceUrls: [TorrentSourceJson] = []

            for sourceUrl in sourceUrls {
                guard let url = URL(string: sourceUrl.urlString) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
                let sourceResponse = try JSONDecoder().decode(SourceJson.self, from: data)

                tempSourceUrls += sourceResponse.sources
            }

            availableSources = tempSourceUrls
        } catch {
            print(error)
        }
    }

    public func installSource(sourceJson: TorrentSourceJson) {
        let backgroundContext = PersistenceController.shared.backgroundContext

        // If a source exists, don't add the new one
        if let name = sourceJson.name {
            let existingSourceRequest = TorrentSource.fetchRequest()
            existingSourceRequest.predicate = NSPredicate(format: "name == %@", name)
            existingSourceRequest.fetchLimit = 1

            let existingSource = try? backgroundContext.fetch(existingSourceRequest).first
            if existingSource != nil {
                Task { @MainActor in
                    toastModel?.toastDescription = "Could not install source \(sourceJson.name ?? "Unknown source") because it is already installed."
                }

                return
            }
        }

        let newTorrentSource = TorrentSource(context: backgroundContext)
        newTorrentSource.name = sourceJson.name
        newTorrentSource.url = sourceJson.url
        newTorrentSource.rowQuery = sourceJson.rowQuery
        newTorrentSource.linkQuery = sourceJson.linkQuery
        newTorrentSource.titleQuery = sourceJson.titleQuery
        newTorrentSource.sizeQuery = sourceJson.sizeQuery

        newTorrentSource.enabled = true

        do {
            try backgroundContext.save()
        } catch {
            Task { @MainActor in
                toastModel?.toastDescription = error.localizedDescription
            }
        }
    }
}

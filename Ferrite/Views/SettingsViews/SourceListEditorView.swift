//
//  SourceListEditorView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct SourceListEditorView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var sourceManager: SourceManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @State private var sourceUrl = ""
    @State private var urlErrorAlertText = ""
    @State private var showUrlErrorAlert = false

    var body: some View {
        NavView {
            Form {
                Section {
                    TextField("Enter URL", text: $sourceUrl)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .alert(isPresented: $showUrlErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(urlErrorAlertText),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("Editing source list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                // Placing this function in the SourceManager causes the view to break on error. Place it here for now.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let backgroundContext = PersistenceController.shared.backgroundContext

                            if sourceUrl.isEmpty || URL(string: sourceUrl) == nil {
                                urlErrorAlertText = "The provided source list is invalid. Please check if the URL is formatted properly."
                                showUrlErrorAlert.toggle()

                                return
                            }

                            let sourceUrlRequest = TorrentSourceUrl.fetchRequest()
                            sourceUrlRequest.predicate = NSPredicate(format: "urlString == %@", sourceUrl)
                            sourceUrlRequest.fetchLimit = 1

                            if let existingSourceUrl = try? backgroundContext.fetch(sourceUrlRequest).first {
                                print("Existing source URL found")
                                PersistenceController.shared.delete(existingSourceUrl, context: backgroundContext)
                            }

                            let newSourceUrl = TorrentSourceUrl(context: backgroundContext)
                            newSourceUrl.urlString = sourceUrl

                            do {
                                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: URL(string: sourceUrl)!))
                                if let rawResponse = try? JSONDecoder().decode(SourceJson.self, from: data) {
                                    newSourceUrl.repoName = rawResponse.repoName
                                }

                                try backgroundContext.save()
                            } catch {
                                urlErrorAlertText = error.localizedDescription
                                showUrlErrorAlert.toggle()
                            }

                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct SourceListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SourceListEditorView()
    }
}

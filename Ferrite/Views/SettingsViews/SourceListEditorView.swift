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
            .alert(isPresented: $sourceManager.showUrlErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(sourceManager.urlErrorAlertText),
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if await sourceManager.addSourceList(sourceUrl: sourceUrl) {
                                dismiss()
                            }
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

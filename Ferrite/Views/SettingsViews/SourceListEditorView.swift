//
//  SourceListEditorView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct SourceListEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var sourceManager: SourceManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @State private var sourceUrl: String

    init(sourceUrl: String = "") {
        _sourceUrl = State(initialValue: sourceUrl)
    }

    var body: some View {
        NavView {
            Form {
                TextField("Enter URL", text: $sourceUrl)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            .onAppear {
                sourceUrl = navModel.selectedSourceList?.urlString ?? ""
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
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if await sourceManager.addSourceList(
                                sourceUrl: sourceUrl,
                                existingSourceList: navModel.selectedSourceList
                            ) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .onDisappear {
                navModel.selectedSourceList = nil
            }
        }
    }
}

struct SourceListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SourceListEditorView()
    }
}

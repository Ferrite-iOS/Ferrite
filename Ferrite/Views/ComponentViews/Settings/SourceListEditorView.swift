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

    @State private var sourceUrlSet = false

    @State private var sourceUrl: String = ""

    var body: some View {
        NavView {
            Form {
                TextField("Enter URL", text: $sourceUrl)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .conditionalId(sourceUrlSet)
            }
            .onAppear {
                sourceUrl = navModel.selectedSourceList?.urlString ?? ""
                sourceUrlSet = true
            }
            .backport.alert(
                isPresented: $sourceManager.showUrlErrorAlert,
                title: "Error",
                message: sourceManager.urlErrorAlertText
            )
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

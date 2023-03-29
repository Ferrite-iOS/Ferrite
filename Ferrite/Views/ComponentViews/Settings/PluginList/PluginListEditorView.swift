//
//  SourceListEditorView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct PluginListEditorView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager
    @EnvironmentObject var logManager: LoggingManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @State private var sourceUrlSet = false
    @State private var showUrlErrorAlert = false

    @State private var pluginListUrl: String = ""
    @State private var urlErrorAlertText: String = ""

    @State private var loadedSelectedList = false

    var body: some View {
        NavView {
            Form {
                TextField("Enter URL", text: $pluginListUrl)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .id(loadedSelectedList)
            }
            .onAppear {
                if let selectedList = navModel.selectedPluginList {
                    pluginListUrl = selectedList.urlString
                    loadedSelectedList.toggle()
                }
            }
            .alert("Error", isPresented: $showUrlErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(urlErrorAlertText)
            }
            .navigationTitle("Editing Plugin List")
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
                            do {
                                try await pluginManager.addPluginList(
                                    pluginListUrl,
                                    existingPluginList: navModel.selectedPluginList
                                )

                                dismiss()
                            } catch {
                                logManager.error("Editing plugin list: \(error)", showToast: false)
                                urlErrorAlertText = error.localizedDescription
                                showUrlErrorAlert.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
}

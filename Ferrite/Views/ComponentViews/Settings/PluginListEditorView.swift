//
//  SourceListEditorView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct PluginListEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @State var selectedPluginList: PluginList?

    @State private var sourceUrlSet = false
    @State private var showUrlErrorAlert = false

    @State private var pluginListUrl: String = ""
    @State private var urlErrorAlertText: String = ""

    var body: some View {
        NavView {
            Form {
                TextField("Enter URL", text: $pluginListUrl)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .conditionalId(sourceUrlSet)
            }
            .backport.onAppear {
                pluginListUrl = selectedPluginList?.urlString ?? ""
                sourceUrlSet = true
            }
            .backport.alert(
                isPresented: $showUrlErrorAlert,
                title: "Error",
                message: urlErrorAlertText
            )
            .navigationTitle("Editing Plugin List")
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
                            do {
                                try await pluginManager.addPluginList(pluginListUrl, existingPluginList: selectedPluginList)
                                presentationMode.wrappedValue.dismiss()
                            } catch {
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

struct PluginListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        PluginListEditorView()
    }
}

//
//  SourceSettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/4/22.
//

import SwiftUI

struct SourceSettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var navModel: NavigationViewModel

    var body: some View {
        NavView {
            List {
                if let selectedSource = navModel.selectedSource {
                    Section(header: "Info") {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(selectedSource.name)

                                Text("v\(selectedSource.version)")
                                    .foregroundColor(.secondary)
                            }

                            Text("by \(selectedSource.author)")
                                .foregroundColor(.secondary)

                            Group {
                                Text("ID: \(selectedSource.id)")

                                if let listId = selectedSource.listId {
                                    Text("List ID: \(listId)")
                                } else {
                                    Text("No list ID found. This source should be removed.")
                                }
                            }
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }
                    }

                    if selectedSource.dynamicBaseUrl {
                        SourceSettingsBaseUrlView(selectedSource: selectedSource)
                    }

                    if let sourceApi = selectedSource.api {
                        SourceSettingsApiView(selectedSourceApi: sourceApi)
                    }

                    SourceSettingsMethodView(selectedSource: selectedSource)
                }
            }
            .listStyle(.insetGrouped)
            .onDisappear {
                PersistenceController.shared.save()
            }
            .navigationTitle("Source settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SourceSettingsBaseUrlView: View {
    @ObservedObject var selectedSource: Source

    @State private var tempBaseUrl: String = ""
    var body: some View {
        Section(
            header: Text("Base URL"),
            footer: Text("Enter the base URL of your server.")
        ) {
            TextField("https://...", text: $tempBaseUrl, onEditingChanged: { isFocused in
                if !isFocused {
                    if tempBaseUrl.last == "/" {
                        selectedSource.baseUrl = String(tempBaseUrl.dropLast())
                    } else {
                        selectedSource.baseUrl = tempBaseUrl
                    }
                }
            })
            .keyboardType(.URL)
            .onAppear {
                tempBaseUrl = selectedSource.baseUrl ?? ""
            }
        }
    }
}

struct SourceSettingsApiView: View {
    @ObservedObject var selectedSourceApi: SourceApi

    @State private var tempClientId: String = ""
    @State private var tempClientSecret: String = ""

    enum Field {
        case secure, plain
    }

    var body: some View {
        Section(
            header: Text("API credentials"),
            footer: Text("Grab the required API credentials from the website. A client secret can be an API token.")
        ) {
            if selectedSourceApi.dynamicClientId {
                TextField("Client ID", text: $tempClientId, onEditingChanged: { isFocused in
                    if !isFocused {
                        selectedSourceApi.clientId = tempClientId
                    }
                })
                .autocapitalization(.none)
                .onAppear {
                    tempClientId = selectedSourceApi.clientId ?? ""
                }
            }

            if selectedSourceApi.clientSecret != nil {
                TextField("Token", text: $tempClientSecret, onEditingChanged: { isFocused in
                    if !isFocused {
                        selectedSourceApi.clientSecret = tempClientSecret
                    }
                })
                .autocapitalization(.none)
                .onAppear {
                    tempClientSecret = selectedSourceApi.clientSecret ?? ""
                }
            }
        }
    }
}

struct SourceSettingsMethodView: View {
    @ObservedObject var selectedSource: Source

    @State private var selectedTempParser: SourcePreferredParser = .none

    var body: some View {
        Picker("Fetch method", selection: $selectedTempParser) {
            if selectedSource.htmlParser != nil {
                Text("Web scraping")
                    .tag(SourcePreferredParser.scraping)
            }

            if selectedSource.rssParser != nil {
                Text("RSS")
                    .tag(SourcePreferredParser.rss)
            }
        }
        .pickerStyle(.inline)
        .onAppear {
            selectedTempParser = SourcePreferredParser(rawValue: selectedSource.preferredParser) ?? .none
        }
        .onChange(of: selectedTempParser) { _ in
            selectedSource.preferredParser = selectedTempParser.rawValue
        }
    }
}

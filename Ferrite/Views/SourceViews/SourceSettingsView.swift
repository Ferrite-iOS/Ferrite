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
                        .padding(.vertical, 2)
                    }

                    if selectedSource.dynamicBaseUrl {
                        SourceSettingsBaseUrlView(selectedSource: selectedSource)
                    }

                    if let sourceApi = selectedSource.api,
                       sourceApi.clientId?.dynamic ?? false || sourceApi.clientSecret?.dynamic ?? false
                    {
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
            if let clientId = selectedSourceApi.clientId, clientId.dynamic {
                TextField("Client ID", text: $tempClientId, onEditingChanged: { isFocused in
                    if !isFocused {
                        clientId.value = tempClientId
                        clientId.timeStamp = Date()
                    }
                })
                .autocapitalization(.none)
                .onAppear {
                    tempClientId = clientId.value ?? ""
                }
            }

            if let clientSecret = selectedSourceApi.clientSecret, clientSecret.dynamic {
                TextField("Token", text: $tempClientSecret, onEditingChanged: { isFocused in
                    if !isFocused {
                        clientSecret.value = tempClientSecret
                        clientSecret.timeStamp = Date()
                    }
                })
                .autocapitalization(.none)
                .onAppear {
                    tempClientSecret = clientSecret.value ?? ""
                }
            }
        }
    }
}

struct SourceSettingsMethodView: View {
    @ObservedObject var selectedSource: Source

    var body: some View {
        Section(header: Text("Fetch method")) {
            if selectedSource.api != nil, selectedSource.jsonParser != nil {
                Button {
                    selectedSource.preferredParser = SourcePreferredParser.siteApi.rawValue
                } label: {
                    HStack {
                        Text("Website API")
                        Spacer()
                        if SourcePreferredParser.siteApi.rawValue == selectedSource.preferredParser {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            if selectedSource.rssParser != nil {
                Button {
                    selectedSource.preferredParser = SourcePreferredParser.rss.rawValue
                } label: {
                    HStack {
                        Text("RSS")
                        Spacer()
                        if SourcePreferredParser.rss.rawValue == selectedSource.preferredParser {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            if selectedSource.htmlParser != nil {
                Button {
                    selectedSource.preferredParser = SourcePreferredParser.scraping.rawValue
                } label: {
                    HStack {
                        Text("Web scraping")
                        Spacer()
                        if SourcePreferredParser.scraping.rawValue == selectedSource.preferredParser {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .dynamicAccentColor(.primary)
    }
}

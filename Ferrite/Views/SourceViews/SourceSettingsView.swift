//
//  SourceSettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/4/22.
//

import SwiftUI

struct SourceSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var navModel: NavigationViewModel

    @State private var tempBaseUrl: String = ""

    var body: some View {
        NavView {
            Form {
                if let selectedSource = navModel.selectedSource {
                    Section("Info") {
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
                        Section(
                            header: Text("Base URL"),
                            footer: Text("Enter the base URL of your server.")
                        ) {
                            TextField("https://...", text: $tempBaseUrl)
                                .onAppear {
                                    tempBaseUrl = selectedSource.baseUrl ?? ""
                                }
                                .onSubmit {
                                    if tempBaseUrl.last == "/" {
                                        selectedSource.baseUrl = String(tempBaseUrl.dropLast())
                                    } else {
                                        selectedSource.baseUrl = tempBaseUrl
                                    }

                                    PersistenceController.shared.save()
                                }
                        }
                    }

                    if let sourceApi = selectedSource.api {
                        SourceSettingsApiView(selectedSourceApi: sourceApi)
                    }

                    SourceSettingsMethodView(selectedSource: selectedSource)
                }
            }
            .navigationTitle("Source settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SourceSettingsApiView: View {
    @ObservedObject var selectedSourceApi: SourceApi

    @State private var tempClientId: String = ""
    @State private var tempClientSecret: String = ""
    @State private var showPassword = false

    @FocusState var inFocus: Field?

    enum Field {
        case secure, plain
    }

    var body: some View {
        Section(
            header: Text("API credentials"),
            footer: Text("Grab the required API credentials from the website. A client secret can be an API token.")
        ) {
            if selectedSourceApi.dynamicClientId {
                TextField("Client ID", text: $tempClientId)
                    .onAppear {
                        tempClientId = selectedSourceApi.clientId ?? ""
                    }
                    .onSubmit {
                        selectedSourceApi.clientId = tempClientId
                        PersistenceController.shared.save()
                    }
            }

            if selectedSourceApi.clientSecret != nil {
                HStack {
                    Group {
                        if showPassword {
                            TextField("Token", text: $tempClientSecret)
                                .focused($inFocus, equals: .plain)
                        } else {
                            SecureField("Token", text: $tempClientSecret)
                                .focused($inFocus, equals: .secure)
                        }
                    }
                    .onAppear {
                        tempClientSecret = selectedSourceApi.clientSecret ?? ""
                    }
                    .onSubmit {
                        selectedSourceApi.clientSecret = tempClientSecret
                        PersistenceController.shared.save()
                    }

                    Spacer()

                    Button {
                        showPassword.toggle()
                        inFocus = showPassword ? .plain : .secure
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }
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
            PersistenceController.shared.save()
        }
    }
}

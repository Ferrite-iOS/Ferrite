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

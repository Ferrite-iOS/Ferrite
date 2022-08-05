//
//  SourceSettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/4/22.
//

import SwiftUI

struct SourceSettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavView {
            Form {
                SourceSettingsMethodView()
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
    @EnvironmentObject var navModel: NavigationViewModel

    @State private var selectedTempParser: SourcePreferredParser = .none

    var body: some View {
        Picker("Fetch method", selection: $selectedTempParser) {
            if navModel.selectedSource?.htmlParser != nil {
                Text("Web scraping")
                    .tag(SourcePreferredParser.scraping)
            }

            if navModel.selectedSource?.rssParser != nil {
                Text("RSS")
                    .tag(SourcePreferredParser.rss)
            }
        }
        .pickerStyle(.inline)
        .onAppear {
            selectedTempParser = SourcePreferredParser(rawValue: navModel.selectedSource?.preferredParser ?? 0) ?? .none
        }
        .onChange(of: selectedTempParser) { newMethod in
            navModel.selectedSource?.preferredParser = newMethod.rawValue
            PersistenceController.shared.save()
        }
    }
}

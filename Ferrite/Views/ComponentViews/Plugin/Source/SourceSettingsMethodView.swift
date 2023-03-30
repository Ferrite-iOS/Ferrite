//
//  SourceSettingsMethodView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/24/23.
//

import SwiftUI

struct SourceSettingsMethodView: View {
    @ObservedObject var selectedSource: Source

    var body: some View {
        Section(header: InlineHeader("Fetch method")) {
            Picker("", selection: $selectedSource.preferredParser) {
                if selectedSource.jsonParser != nil {
                    Text("Website API").tag(SourcePreferredParser.siteApi.rawValue)
                }

                if selectedSource.rssParser != nil {
                    Text("RSS").tag(SourcePreferredParser.rss.rawValue)
                }

                if selectedSource.htmlParser != nil {
                    Text("Web scraping").tag(SourcePreferredParser.scraping.rawValue)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .tint(.primary)
    }
}

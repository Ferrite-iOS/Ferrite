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
            if selectedSource.jsonParser != nil {
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
        .tint(.primary)
    }
}

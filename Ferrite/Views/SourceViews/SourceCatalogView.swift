//
//  SourceCatalogButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct SourceCatalogButtonView: View {
    @EnvironmentObject var sourceManager: SourceManager

    let availableSource: SourceJson

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(availableSource.name)
                    Text("v\(availableSource.version)")
                        .foregroundColor(.secondary)
                }
                
                Text("by \(availableSource.author ?? "Unknown")")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Install") {
                sourceManager.installSource(sourceJson: availableSource)
            }
        }
    }
}

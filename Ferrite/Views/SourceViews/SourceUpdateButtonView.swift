//
//  SourceUpdateButtonView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct SourceUpdateButtonView: View {
    @EnvironmentObject var sourceManager: SourceManager

    let updatedSource: SourceJson

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(updatedSource.name)
                    Text("v\(updatedSource.version)")
                        .foregroundColor(.secondary)
                }
                
                Text("by \(updatedSource.author ?? "Unknown")")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Update") {
                sourceManager.installSource(sourceJson: updatedSource, doUpsert: true)
            }
        }
    }
}

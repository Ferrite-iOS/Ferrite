//
//  DebridLabelView.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/27/22.
//

import SwiftUI

struct DebridLabelView: View {
    @EnvironmentObject var debridManager: DebridManager

    var result: SearchResult

    let debridAbbreviation: String

    var body: some View {
        Text(debridAbbreviation)
            .fontWeight(.bold)
            .padding(2)
            .background {
                Group {
                    switch debridManager.matchSearchResult(result: result) {
                    case .full:
                        Color.green
                    case .partial:
                        Color.orange
                    case .none:
                        Color.red
                    }
                }
                .cornerRadius(4)
                .opacity(0.5)
            }
    }
}

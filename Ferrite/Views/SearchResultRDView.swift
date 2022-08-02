//
//  SearchResultRDView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//

import SwiftUI

struct SearchResultRDView: View {
    @EnvironmentObject var debridManager: DebridManager

    @AppStorage("RealDebrid.Enabled") var realDebridEnabled = false

    var result: SearchResult

    var body: some View {
        HStack {
            Text(result.source)

            Spacer()

            if let seeders = result.seeders {
                Text("S: \(seeders)")
            }

            if let leechers = result.leechers {
                Text("L: \(leechers)")
            }

            Text(result.size)

            if realDebridEnabled {
                Text("RD")
                    .fontWeight(.bold)
                    .padding(2)
                    .background {
                        switch debridManager.matchSearchResult(result: result) {
                        case .full:
                            Color.green
                                .cornerRadius(4)
                                .opacity(0.5)
                        case .partial:
                            Color.orange
                                .cornerRadius(4)
                                .opacity(0.5)
                        case .none:
                            Color.red
                                .cornerRadius(4)
                                .opacity(0.5)
                        }
                    }
            }
        }
        .font(.caption)
    }
}

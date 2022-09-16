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

            if let size = result.size {
                Text(size)
            }

            if realDebridEnabled {
                Text("RD")
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
        .font(.caption)
    }
}

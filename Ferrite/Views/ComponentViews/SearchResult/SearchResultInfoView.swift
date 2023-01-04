//
//  SearchResultRDView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//

import SwiftUI

struct SearchResultInfoView: View {
    @EnvironmentObject var debridManager: DebridManager

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

            DebridLabelView(magnet: result.magnet)
        }
        .font(.caption)
    }
}

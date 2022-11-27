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

            if debridManager.selectedDebridType == .realDebrid {
                DebridLabelView(result: result, debridAbbreviation: "RD")
            }

            if debridManager.selectedDebridType == .allDebrid {
                DebridLabelView(result: result, debridAbbreviation: "AD")
            }
        }
        .font(.caption)
    }
}

//
//  DebridLabelView.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/27/22.
//

import SwiftUI

struct DebridLabelView: View {
    @EnvironmentObject var debridManager: DebridManager

    @State var cloudLinks: [String] = []
    var magnet: Magnet?

    var body: some View {
        if let selectedDebridType = debridManager.selectedDebridType {
            Text(selectedDebridType.toString(abbreviated: true))
                .fontWeight(.bold)
                .padding(2)
                .background {
                    Group {
                        if let magnet, cloudLinks.isEmpty {
                            switch debridManager.matchMagnetHash(magnet) {
                            case .full:
                                Color.green
                            case .partial:
                                Color.orange
                            case .none:
                                Color.red
                            }
                        } else if cloudLinks.count == 1 {
                            Color.green
                        } else if cloudLinks.count > 1 {
                            Color.orange
                        } else {
                            Color.red
                        }
                    }
                    .cornerRadius(4)
                    .opacity(0.5)
                }
        }
    }
}

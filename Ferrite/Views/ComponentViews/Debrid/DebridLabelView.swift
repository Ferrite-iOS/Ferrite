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
            Tag(
                name: selectedDebridType.toString(abbreviated: true),
                color: getTagColor(),
                horizontalPadding: 5,
                verticalPadding: 3
            )
        }
    }

    func getTagColor() -> Color {
        if let magnet, cloudLinks.isEmpty {
            switch debridManager.matchMagnetHash(magnet) {
            case .full:
                return Color.green
            case .partial:
                return Color.orange
            case .none:
                return Color.red
            }
        } else if cloudLinks.count == 1 {
            return Color.green
        } else if cloudLinks.count > 1 {
            return Color.orange
        } else {
            return Color.red
        }
    }
}

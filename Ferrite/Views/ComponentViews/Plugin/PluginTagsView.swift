//
//  PluginTagView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/7/23.
//

import SwiftUI

struct PluginTagsView: View {
    let tags: [PluginTagJson]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Tag(name: tag.name, color: tag.colorHex.map { Color(hex: $0) })
                }
            }
        }
    }
}

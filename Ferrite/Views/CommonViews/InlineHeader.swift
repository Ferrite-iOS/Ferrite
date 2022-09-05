//
//  InlineHeader.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/5/22.
//

import SwiftUI

struct InlineHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Group {
            if #available(iOS 16, *) {
                Text(title)
                    .padding(.vertical, 5)
            } else {
                Text(title)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 20)
        .listRowInsets(EdgeInsets())
    }
}

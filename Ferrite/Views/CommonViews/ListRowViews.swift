//
//  ListRowViews.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//
//  List row button, text, and link boilerplate
//

import SwiftUI

struct ListRowLinkView: View {
    let text: String
    let link: String

    var body: some View {
        HStack {
            Link(text, destination: URL(string: link)!)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "arrow.up.forward.app.fill")
                .foregroundColor(.gray)
        }
    }
}

struct ListRowButtonView: View {
    let text: String
    let systemImage: String?
    let action: () -> Void

    init(_ text: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        HStack {
            Button(text) {
                action()
            }

            Spacer()

            if let imageName = systemImage {
                Image(systemName: imageName)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ListRowTextView: View {
    let leftText: String
    var rightText: String?
    var rightSymbol: String?

    var body: some View {
        HStack {
            Text(leftText)

            Spacer()

            if let rightText = rightText {
                Text(rightText)
            } else {
                Image(systemName: rightSymbol!)
                    .foregroundColor(.gray)
            }
        }
    }
}

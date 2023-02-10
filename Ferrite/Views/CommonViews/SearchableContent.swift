//
//  SearchableContent.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/11/23.
//
//  View to link animations together with searchbar
//  Passes through geometry proxy and last height vars for any comparison
//

import SwiftUI

struct SearchableContent<Content: View>: View {
    @Binding var searching: Bool

    @State private var lastHeight: CGFloat = 0.0

    @ViewBuilder var content: (Bool) -> Content

    var body: some View {
        GeometryReader { geom in
            // Return if the height has changed as a closure variable for child transactions
            content(geom.size.height != lastHeight)
                .backport.onAppear {
                    lastHeight = geom.size.height
                }
                .onChange(of: geom.size.height) { newHeight in
                    lastHeight = newHeight
                }
                .transaction {
                    if geom.size.height != lastHeight && searching {
                        $0.animation = .default.speed(2)
                    }
                }
        }
    }
}

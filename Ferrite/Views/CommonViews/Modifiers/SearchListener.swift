//
//  SearchListener.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/29/23.
//
//  Communicate isSearching back to the parent view
//

import SwiftUI

struct SearchListenerModifier: ViewModifier {
    @Environment(\.isSearching) var isSearchingEnvironment

    @Binding var isSearching: Bool

    func body(content: Content) -> some View {
        content
            .background {
                EmptyView()
                    .onChange(of: isSearchingEnvironment) { newValue in
                        isSearching = newValue
                    }
            }
    }
}

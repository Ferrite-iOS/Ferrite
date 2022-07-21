//
//  Collection.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/4/22.
//

import Foundation

extension Collection {
    // From https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

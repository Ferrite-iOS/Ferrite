//
//  Array.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/4/22.
//

import Foundation

extension Array {
    // From https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

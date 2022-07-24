//
//  Data.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/4/22.
//

import Foundation

extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

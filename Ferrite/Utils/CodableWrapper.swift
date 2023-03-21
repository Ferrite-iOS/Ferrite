//
//  CodableWrapper.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/20/23.
//
//  From https://forums.swift.org/t/rawrepresentable-conformance-leads-to-crash/51912/4
//  Prevents recursion when using Codable with RawRepresentable without needing manual conformance

import Foundation

struct CodableWrapper<Value: Codable> {
    var value: Value
}

extension CodableWrapper: RawRepresentable {
    var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(value),
            let string = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return string
    }
    
    init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Value.self, from: data)
        else {
            return nil
        }
        value = decoded
    }
}

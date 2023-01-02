//
//  DebridManagerModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/27/22.
//

import Foundation

// MARK: - Universal IA enum (IA = InstantAvailability)

public enum IAStatus: Codable, Hashable, Sendable {
    case full
    case partial
    case none
}

// MARK: - Enum for debrid differentiation. 0 is nil

public enum DebridType: Int, Codable, Hashable, CaseIterable {
    case realDebrid = 1
    case allDebrid = 2
    case premiumize = 3

    func toString(abbreviated: Bool = false) -> String {
        switch self {
        case .realDebrid:
            return abbreviated ? "RD" : "RealDebrid"
        case .allDebrid:
            return abbreviated ? "AD" : "AllDebrid"
        case .premiumize:
            return abbreviated ? "PM" : "Premiumize"
        }
    }
}

// Wrapper struct for magnet links to contain both the link and hash for easy access
public struct Magnet: Codable, Hashable, Sendable {
    let link: String?
    let hash: String
}

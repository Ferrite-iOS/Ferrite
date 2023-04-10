//
//  DebridManagerModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 11/27/22.
//

import Base32
import Foundation

// MARK: - Universal IA enum (IA = InstantAvailability)

public enum IAStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case full = "Cached"
    case partial = "Batch"
    case none = "Uncached"
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

    func website() -> String {
        switch self {
        case .realDebrid:
            return "https://real-debrid.com"
        case .allDebrid:
            return "https://alldebrid.com"
        case .premiumize:
            return "https://premiumize.me"
        }
    }
}

// Wrapper struct for magnet links to contain both the link and hash for easy access
public struct Magnet: Codable, Hashable, Sendable {
    var hash: String?
    var link: String?

    init(hash: String?, link: String?, title: String? = nil, trackers: [String]? = nil) {
        if let hash, link == nil {
            self.hash = parseHash(hash)
            self.link = generateLink(hash: hash, title: title, trackers: trackers)
        } else if let link, hash == nil {
            self.link = link
            self.hash = parseHash(extractHash(link: link))
        } else {
            self.hash = parseHash(hash)
            self.link = link
        }
    }

    func generateLink(hash: String, title: String?, trackers: [String]?) -> String {
        var magnetLinkArray = ["magnet:?xt=urn:btih:", hash]

        if let title, let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            magnetLinkArray.append("&dn=\(encodedTitle)")
        }

        if let trackers {
            for trackerUrl in trackers {
                if URL(string: trackerUrl) != nil,
                   let encodedUrlString = trackerUrl.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                {
                    magnetLinkArray.append("&tr=\(encodedUrlString)")
                }
            }
        }

        return magnetLinkArray.joined()
    }

    func extractHash(link: String) -> String? {
        if let firstSplit = link.split(separator: ":")[safe: 3],
           let tempHash = firstSplit.split(separator: "&")[safe: 0]
        {
            return String(tempHash)
        } else {
            return nil
        }
    }

    // Is this a Base32hex hash?
    func parseHash(_ magnetHash: String?) -> String? {
        guard let magnetHash else {
            return nil
        }

        if magnetHash.count == 32 {
            let decryptedMagnetHash = base32DecodeToData(String(magnetHash))
            return decryptedMagnetHash?.hexEncodedString()
        } else {
            return String(magnetHash).lowercased()
        }
    }
}

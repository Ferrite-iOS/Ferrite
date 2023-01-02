//
//  String.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/31/22.
//
//

import Foundation

extension String {
    // From https://www.hackingwithswift.com/example-code/strings/how-to-capitalize-the-first-letter-of-a-string
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    //  From https://stackoverflow.com/a/59307884
    private func compare(toVersion targetVersion: String) -> ComparisonResult {
        let versionDelimiter = "."
        var result: ComparisonResult = .orderedSame
        var versionComponents = components(separatedBy: versionDelimiter)
        var targetComponents = targetVersion.components(separatedBy: versionDelimiter)

        while versionComponents.count < targetComponents.count {
            versionComponents.append("0")
        }

        while targetComponents.count < versionComponents.count {
            targetComponents.append("0")
        }

        for (version, target) in zip(versionComponents, targetComponents) {
            result = version.compare(target, options: .numeric)
            if result != .orderedSame {
                break
            }
        }

        return result
    }

    static func == (lhs: String, rhs: String) -> Bool { lhs.compare(toVersion: rhs) == .orderedSame }
    static func < (lhs: String, rhs: String) -> Bool { lhs.compare(toVersion: rhs) == .orderedAscending }
    static func <= (lhs: String, rhs: String) -> Bool { lhs.compare(toVersion: rhs) != .orderedDescending }
    static func > (lhs: String, rhs: String) -> Bool { lhs.compare(toVersion: rhs) == .orderedDescending }
    static func >= (lhs: String, rhs: String) -> Bool { lhs.compare(toVersion: rhs) != .orderedAscending }
}

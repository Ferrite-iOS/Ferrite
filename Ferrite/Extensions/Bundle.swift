//
//  Bundle.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/6/22.
//

import Foundation

extension Bundle {
    var commitHash: String? {
        infoDictionary?["GitCommitHash"] as? String
    }

    var isNightly: Bool {
        infoDictionary?["IsNightly"] as? Bool ?? false
    }
}

//
//  OperatingSystemVersion.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/23/23.
//

import Foundation

extension OperatingSystemVersion {
    func toString() -> String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}

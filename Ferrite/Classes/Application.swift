//
//  Application.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/16/22.
//
//  A thread-safe UIApplication alternative for specifying app properties
//

import Foundation

public class Application {
    static let shared = Application()

    // OS name for Plugins to read. Lowercase for ease of use
    let os = "ios"

    // Minimum OS version that Ferrite runs on
    let minVersion = OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0)

    // Grabs the current user's OS version
    let osVersion: OperatingSystemVersion = ProcessInfo().operatingSystemVersion

    // Application version and build variables
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    // Debug = development, Nightly = actions, Release = stable
    var buildType: String {
        #if DEBUG
        return "Debug"
        #else
        if Bundle.main.isNightly {
            return "Nightly"
        } else {
            return "Release"
        }
        #endif
    }
}

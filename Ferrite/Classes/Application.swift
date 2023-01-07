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

    let osVersion: OperatingSystemVersion = ProcessInfo().operatingSystemVersion
}

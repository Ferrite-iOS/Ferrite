//
//  UIApplication.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//

import SwiftUI

// Extensions to get the version/build number for AboutView
extension UIApplication {
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    var buildType: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
}

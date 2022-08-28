//
//  SettingsModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/11/22.
//

import Foundation

public enum DefaultMagnetActionType: Int, CaseIterable {
    // Let the user choose
    case none = 0

    // Open in actions come first
    case webtor = 1

    // Sharing actions come last
    case shareMagnet = 2
}

public enum DefaultDebridActionType: Int, CaseIterable {
    // Let the user choose
    case none = 0

    // Open in actions come first
    case outplayer = 1
    case vlc = 2
    case infuse = 3

    // Sharing actions come last
    case shareDownload = 4
}

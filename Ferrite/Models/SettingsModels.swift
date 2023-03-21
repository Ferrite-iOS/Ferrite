//
//  SettingsModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/20/23.
//

import Foundation

enum DefaultAction: Codable, CaseIterable, Hashable {
    static var allCases: [DefaultAction] {
        [.none, .share, .kodi, .custom(name: "", listId: "")]
    }

    case none
    case share
    case kodi
    case custom(name: String, listId: String)
}

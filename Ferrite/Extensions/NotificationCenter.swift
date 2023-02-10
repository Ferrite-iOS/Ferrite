//
//  NotificationCenter.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/3/22.
//

import Foundation

extension Notification.Name {
    static var didDeleteBookmark: Notification.Name {
        Notification.Name("Deleted bookmark")
    }

    static var didDeletePlugin: Notification.Name {
        Notification.Name("Deleted plugin")
    }
}

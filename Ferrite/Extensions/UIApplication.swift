//
//  UIApplication.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/27/23.
//

import UIKit

extension UIApplication {
    // From https://stackoverflow.com/questions/69650504/how-to-get-rid-of-message-windows-was-deprecated-in-ios-15-0-use-uiwindowsc
    var currentUIWindow: UIWindow? {
        return UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
    }
}

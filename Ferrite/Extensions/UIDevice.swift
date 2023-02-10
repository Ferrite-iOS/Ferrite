//
//  UIDevice.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/16/23.
//

import SwiftUI

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            let keyWindow = UIApplication.shared.windows.filter(\.isKeyWindow).first
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
        return false
    }
}

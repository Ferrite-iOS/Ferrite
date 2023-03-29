//
//  UIDevice.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/16/23.
//

import UIKit

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.currentUIWindow?.safeAreaInsets.bottom ?? 0 > 0
        } else {
            return false
        }
    }
}

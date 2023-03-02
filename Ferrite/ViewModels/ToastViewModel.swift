//
//  ToastViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/19/22.
//

import SwiftUI

@MainActor
class ToastViewModel: ObservableObject {
    enum ToastType: Identifiable {
        var id: Int {
            hashValue
        }

        case info
        case error
    }

    // Toast variables
    @Published var toastDescription: String? = nil {
        didSet {
            Task {
                try? await Task.sleep(seconds: 0.1)
                showToast = true

                try? await Task.sleep(seconds: 5)

                showToast = false
                toastType = .error
            }
        }
    }

    @Published var showToast: Bool = false

    @Published var indeterminateToastDescription: String? = nil
    @Published var indeterminateCancelAction: (() -> Void)? = nil
    @Published var showIndeterminateToast: Bool = false

    public func updateToastDescription(_ description: String, newToastType: ToastType? = nil) {
        if let newToastType {
            toastType = newToastType
        }

        toastDescription = description
    }

    public func updateIndeterminateToast(_ description: String, cancelAction: (() -> Void)?) {
        indeterminateToastDescription = description

        if let cancelAction {
            indeterminateCancelAction = cancelAction
        }

        if !showIndeterminateToast {
            showIndeterminateToast = true
        }
    }

    public func hideIndeterminateToast() {
        showIndeterminateToast = false
        indeterminateToastDescription = ""
        indeterminateCancelAction = nil
    }

    // Default the toast type to error since the majority of toasts are errors
    @Published var toastType: ToastType = .error
}

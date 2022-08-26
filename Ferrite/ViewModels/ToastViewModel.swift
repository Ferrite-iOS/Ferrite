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

    // Default the toast type to error since the majority of toasts are errors
    @Published var toastType: ToastType = .error
}

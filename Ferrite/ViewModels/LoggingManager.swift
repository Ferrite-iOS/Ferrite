//
//  ToastViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/19/22.
//

import SwiftUI

@MainActor
class LoggingManager: ObservableObject {
    struct Log: Hashable {
        let level: LogLevel
        let message: String
        let timeStamp: Date = .init()

        func toMessage() -> String {
            "[\(level.rawValue)]: \(message)"
        }
    }

    enum LogLevel: String, Identifiable {
        var id: Int {
            hashValue
        }

        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }

    @Published var messageArray: [Log] = []

    // Toast variables
    @Published var toastDescription: String? = nil {
        didSet {
            Task {
                try? await Task.sleep(seconds: 0.1)
                showToast = true

                try? await Task.sleep(seconds: 3)

                showToast = false
                toastType = .error
            }
        }
    }

    @Published var showToast: Bool = false
    // Default the toast type to error since the majority of toasts are errors
    @Published var toastType: Logger.LogLevel = .error
    var showErrorToasts: Bool {
        UserDefaults.standard.bool(forKey: "Debug.ShowErrorToasts")
    }

    @Published var indeterminateToastDescription: String? = nil
    @Published var indeterminateCancelAction: (() -> Void)? = nil
    @Published var showIndeterminateToast: Bool = false

    // MARK: - Logging functions

    public func info(_ message: String,
                     description: String? = nil)
    {
        let log = Log(
            level: .info,
            message: message
        )

        if let description {
            toastType = .info
            toastDescription = description
        }

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }

    public func warn(_ message: String,
                     description: String? = nil)
    {
        let log = Log(
            level: .warn,
            message: message
        )

        if let description {
            toastType = .warn
            toastDescription = description
        }

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }

    public func error(_ message: String,
                      description: String? = nil,
                      showToast: Bool = true)
    {
        let log = Log(
            level: .error,
            message: message
        )

        // If a task is run in parallel, don't show a toast on error
        if showToast && showErrorToasts {
            toastDescription = description.map { $0 } ?? "An error was logged"
        }

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }

    // MARK: - Indeterminate functions

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
}

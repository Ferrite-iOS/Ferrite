//
//  ToastViewModel.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/19/22.
//

import SwiftUI

@MainActor
class LoggingManager: ObservableObject {
    let logFormatter = DateFormatter()

    struct Log: Hashable {
        let level: LogLevel
        let message: String
        let timeStamp: Date = .init()
        var isExpanded: Bool = false

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
    @Published var showLogExportedAlert = false

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

    init() {
        logFormatter.dateStyle = .short
        logFormatter.timeStyle = .long
    }

    // MARK: - Logging functions
    // TODO: Maybe append to a constant logfile?

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
        // Only gate generic error toasts behind the settings option
        if showToast {
            if let description {
                toastDescription = description
            } else if showErrorToasts {
                toastDescription = "An error was logged"
            }
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

    public func exportLogs() {
        logFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let logFileName = "ferrite_session_\(logFormatter.string(from: Date())).txt"
        let logFolderPath = FileManager.default.appDirectory.appendingPathComponent("Logs")
        let logPath = logFolderPath.appendingPathComponent(logFileName)

        logFormatter.dateStyle = .short
        logFormatter.timeStyle = .long
        let joinedMessages = messageArray.map { "\(logFormatter.string(from: $0.timeStamp)): \($0.toMessage())" }.joined(separator: "\n")

        do {
            if FileManager.default.fileExists(atPath: logPath.path) {
                try FileManager.default.removeItem(at: logPath)
            } else if !FileManager.default.fileExists(atPath: logFolderPath.path) {
                try FileManager.default.createDirectory(atPath: logFolderPath.path, withIntermediateDirectories: true, attributes: nil)
            }

            try joinedMessages.write(to: logPath, atomically: true, encoding: .utf8)

            self.info("Log \(logFileName) was written to path \(logPath.description)")
            showLogExportedAlert.toggle()
        } catch {
            self.error(
                "Log export for file \(logFileName): \(error)",
                description: "Exporting your log file failed. Please check the logs page."
            )
        }
    }
}

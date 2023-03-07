//
//  Logger.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/8/23.
//

import Foundation

public class Logger {
    var messageArray: [Log] = []

    struct Log: Hashable {
        let level: LogLevel
        let description: String
        let timeStamp: Date = .init()

        func toMessage() -> String {
            "[\(level.rawValue)]: \(description)"
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

    func info(_ message: String) {
        let log = Log(
            level: .info,
            description: message
        )

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }

    func warn(_ message: String) {
        let log = Log(
            level: .warn,
            description: message
        )

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }

    func error(_ message: String) {
        let log = Log(
            level: .error,
            description: message
        )

        messageArray.append(log)

        print("LOG: \(log.toMessage())")
    }
}

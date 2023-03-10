//
//  DateFormatter.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/4/22.
//

import Foundation

// A static DateFormatter is better than initializing new ones
extension DateFormatter {
    static let historyDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "ddMMyyyy"

        return df
    }()
}

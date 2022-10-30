//
//  FileManager.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/17/22.
//

import Foundation

extension FileManager {
    var appDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

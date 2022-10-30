//
//  URL.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/20/22.
//

import Foundation

extension URL {
    // From https://github.com/Aidoku/Aidoku/blob/main/Shared/Extensions/FileManager.swift
    // Used for FileManager
    var contentsByDateAdded: [URL] {
        if let urls = try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) {
            return urls.sorted {
                ((try? $0.resourceValues(forKeys: [.addedToDirectoryDateKey]))?.addedToDirectoryDate ?? Date.distantPast)
                    >
                    ((try? $1.resourceValues(forKeys: [.addedToDirectoryDateKey]))?.addedToDirectoryDate ?? Date.distantPast)
            }
        }

        let contents = try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)

        return contents ?? []
    }
}

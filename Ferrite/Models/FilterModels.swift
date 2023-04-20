//
//  FilterModels.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/10/23.
//

import Foundation

enum FilterType {
    case source
    case IA
    case sort
}

enum SortFilter: String, Hashable, CaseIterable {
    case seeders = "Seeders"
    case leechers = "Leechers"
    case size = "Size"
}

//
//  InlinedList.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/4/22.
//
//  Removes the top padding on unsectioned lists
//  If a list is sectioned, see InlineHeader
//

import Introspect
import SwiftUI

struct InlinedListModifier: ViewModifier {
    let inset: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .introspectCollectionView { collectionView in
                    collectionView.contentInset.top = inset
                }
        } else {
            content
                .introspectTableView { tableView in
                    tableView.contentInset.top = inset
                }
        }
    }
}

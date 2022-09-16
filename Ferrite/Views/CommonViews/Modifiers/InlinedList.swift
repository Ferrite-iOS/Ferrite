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

struct InlinedList: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .introspectCollectionView { collectionView in
                    collectionView.contentInset.top = -20
                }
        } else {
            content
                .introspectTableView { tableView in
                    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
                }
        }
    }
}

//
//  SearchAppearance.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/14/23.
//

import Introspect
import SwiftUI

struct CustomScopeBarModifier<V: View>: ViewModifier {
    let scopeBarContent: V
    @State private var hostingController: UIHostingController<V>?

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .backport.introspectSearchController { searchController in

                    // MARK: One-time setup

                    guard hostingController == nil else { return }

                    searchController.hidesNavigationBarDuringPresentation = true
                    searchController.searchBar.showsScopeBar = true
                    searchController.searchBar.scopeButtonTitles = [""]
                    (searchController.searchBar.value(forKey: "_scopeBar") as? UIView)?.isHidden = true

                    let hostingController = UIHostingController(rootView: scopeBarContent)
                    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                    hostingController.view.backgroundColor = .clear

                    guard let containerView = searchController.searchBar.value(forKey: "_scopeBarContainerView") as? UIView else {
                        return
                    }
                    containerView.addSubview(hostingController.view)

                    NSLayoutConstraint.activate([
                        hostingController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                        hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                        hostingController.view.heightAnchor.constraint(equalTo: containerView.heightAnchor)
                    ])

                    self.hostingController = hostingController
                }
                .introspectNavigationController { navigationController in
                    if #available(iOS 16, *) {
                        navigationController.viewControllers.first?.navigationItem.preferredSearchBarPlacement = .stacked
                    }

                    navigationController.navigationBar.prefersLargeTitles = true
                    navigationController.navigationBar.sizeToFit()
                }
        } else {
            VStack {
                scopeBarContent
                content
                Spacer()
            }
        }
    }
}

//
//  SearchAppearance.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/14/23.
//

import SwiftUI
import Introspect

struct CustomScopeBarModifier<V: View>: ViewModifier {
    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    let hostingContent: V
    @State private var hostingController: UIHostingController<V>?

    init(hostingContent: V) {
        self.hostingContent = hostingContent
    }

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .backport.introspectSearchController { searchController in
                    guard hostingController == nil else { return }

                    searchController.hidesNavigationBarDuringPresentation = true
                    searchController.searchBar.autocorrectionType = autocorrectSearch ? .default : .no
                    searchController.searchBar.autocapitalizationType = autocorrectSearch ? .sentences : .none
                    searchController.searchBar.showsScopeBar = true
                    searchController.searchBar.scopeButtonTitles = [""]
                    (searchController.searchBar.value(forKey: "_scopeBar") as? UIView)?.isHidden = true

                    let hostingController = UIHostingController(rootView: hostingContent)
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
                    navigationController.navigationBar.prefersLargeTitles = true
                    navigationController.navigationBar.sizeToFit()
                }
        } else {
            VStack {
                hostingContent
                content
                Spacer()
            }
            .backport.introspectSearchController { searchController in
                searchController.searchBar.autocorrectionType = autocorrectSearch ? .default : .no
                searchController.searchBar.autocapitalizationType = autocorrectSearch ? .sentences : .none
            }
        }
    }
}

//
//  ExpandedSearchable.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/8/23.
//

import SwiftUI

public extension View {
    // A dismissAction must be added in the parent view struct due to lifecycle issues
    func expandedSearchable(text: Binding<String>,
                            isSearching: Binding<Bool>? = nil,
                            isEditingSearch: Binding<Bool>? = nil,
                            prompt: String? = nil,
                            dismiss: Binding<() -> Void>? = nil,
                            scopeBarContent: @escaping () -> some View = {
                                EmptyView()
                            },
                            onSubmit: (() -> Void)? = nil,
                            onCancel: (() -> Void)? = nil) -> some View
    {
        overlay(
            SearchBar(
                searchText: text,
                isSearching: isSearching ?? Binding(get: { true }, set: { _, _ in }),
                isEditingSearch: isEditingSearch ?? Binding(get: { true }, set: { _, _ in }),
                prompt: prompt ?? "Search",
                dismiss: dismiss ?? Binding(get: { {} }, set: { _, _ in }),
                scopeBarContent: scopeBarContent,
                onSubmit: onSubmit,
                onCancel: onCancel
            )
            .frame(width: 0, height: 0)
        )
        .environment(\.esIsSearching, isSearching?.wrappedValue ?? false)
        .environment(\.esDismissSearch, ESDismissSearchAction(action: dismiss?.wrappedValue ?? {}))
    }

    func esAutocapitalization(_ autocapitalizationType: UITextAutocapitalizationType) -> some View {
        environment(\.esAutocapitalizationType, autocapitalizationType)
    }
}

struct ESIsSearching: EnvironmentKey {
    static var defaultValue: Bool = false
}

struct ESDismissSearchAction: EnvironmentKey {
    static var defaultValue: ESDismissSearchAction = .init(action: {})

    let action: () -> Void

    func callAsFunction() {
        action()
    }
}

struct ESAutocapitalization: EnvironmentKey {
    static var defaultValue: UITextAutocapitalizationType = .none
}

extension EnvironmentValues {
    var esIsSearching: Bool {
        get { self[ESIsSearching.self] }
        set { self[ESIsSearching.self] = newValue }
    }

    var esDismissSearch: ESDismissSearchAction {
        get { self[ESDismissSearchAction.self] }
        set { self[ESDismissSearchAction.self] = newValue }
    }

    var esAutocapitalizationType: UITextAutocapitalizationType {
        get { self[ESAutocapitalization.self] }
        set { self[ESAutocapitalization.self] = newValue }
    }
}

struct SearchBar<ScopeContent: View>: UIViewControllerRepresentable {
    var searchController: UISearchController = .init(searchResultsController: nil)

    @Environment(\.autocorrectionDisabled) var autocorrectionDisabled
    @Environment(\.esAutocapitalizationType) var autocapitalization

    // Passed in vars
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var isEditingSearch: Bool
    var prompt: String
    @Binding var dismiss: () -> Void
    let scopeBarContent: () -> ScopeContent
    let onSubmit: (() -> Void)?
    let onCancel: (() -> Void)?

    class Coordinator: NSObject, UISearchBarDelegate, UISearchResultsUpdating {
        let parent: SearchBar

        init(_ parent: SearchBar) {
            self.parent = parent
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.searchText = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            parent.isEditingSearch = true
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            parent.isEditingSearch = false
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            if let onSubmit = parent.onSubmit {
                onSubmit()
            }
        }

        // Not necessary since you can listen to isSearching
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.searchText = ""
            if let onCancel = parent.onCancel {
                onCancel()
            }
        }

        func updateSearchResults(for searchController: UISearchController) {
            parent.isSearching = searchController.isActive
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> NavSearchBarWrapper {
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = context.coordinator
        searchController.searchResultsUpdater = context.coordinator
        searchController.searchBar.autocorrectionType = autocorrectionDisabled ? .no : .yes
        searchController.searchBar.autocapitalizationType = autocapitalization

        dismiss = {
            searchText = ""
            searchController.isActive = false
        }

        if ScopeContent.self != EmptyView.self {
            setupScopeBar(scopeBarContent())
        }

        return NavSearchBarWrapper(searchController: searchController)
    }

    // TODO: Split into a separate ViewController class for root search controller modification
    // Or put this in the coordinator
    func updateUIViewController(_ controller: NavSearchBarWrapper, context: Context) {
        controller.searchController.searchBar.placeholder = prompt
        controller.searchController.searchBar.autocorrectionType = autocorrectionDisabled ? .no : .yes
        controller.searchController.searchBar.autocapitalizationType = autocapitalization
    }

    func setupScopeBar(_ content: ScopeContent) {
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = [""]
        (searchController.searchBar.value(forKey: "_scopeBar") as? UIView)?.isHidden = true

        guard
            let containerView = searchController.searchBar.value(forKey: "_scopeBarContainerView") as? UIView,
            !containerView.subviews.contains(where: { String(describing: $0.classForCoder).contains("UIHostingView") })
        else {
            return
        }

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        containerView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
    }

    // Appends search controller to the nearest NavigationView
    class NavSearchBarWrapper: UIViewController {
        var searchController: UISearchController
        init(searchController: UISearchController) {
            self.searchController = searchController
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            setup()
        }

        override func viewDidAppear(_ animated: Bool) {
            setup()
        }

        // Acts on the parent of this VC which is the representable view
        private func setup() {
            parent?.navigationItem.searchController = searchController
            parent?.navigationItem.hidesSearchBarWhenScrolling = false

            if #available(iOS 16, *) {
                parent?.navigationItem.preferredSearchBarPlacement = .stacked
            }

            // Makes search bar appear when application starts
            parent?.navigationController?.navigationBar.sizeToFit()
        }
    }
}

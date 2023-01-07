//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import Introspect
import SwiftUI
import SwiftUIX

struct SourcesView: View {
    @EnvironmentObject var sourceManager: SourceManager
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    @AppStorage("Behavior.AutocorrectSearch") var autocorrectSearch = true

    @State private var checkedForSources = false
    @State private var isEditingSearch = false
    @State private var isSearching = false

    @State private var viewTask: Task<Void, Never>? = nil
    @State private var searchText: String = ""
    @State private var filteredUpdatedSources: [SourceJson] = []
    @State private var filteredAvailableSources: [SourceJson] = []
    @State private var sourcePredicate: NSPredicate?

    var body: some View {
        NavView {
            DynamicFetchRequest(predicate: sourcePredicate) { (installedSources: FetchedResults<Source>) in
                ZStack {
                    if !checkedForSources {
                        ProgressView()
                    } else if installedSources.isEmpty, sourceManager.availableSources.isEmpty {
                        EmptyInstructionView(title: "No Sources", message: "Add a source list in Settings")
                    } else {
                        List {
                            if !filteredUpdatedSources.isEmpty {
                                Section(header: InlineHeader("Updates")) {
                                    ForEach(filteredUpdatedSources, id: \.self) { source in
                                        SourceUpdateButtonView(updatedSource: source)
                                    }
                                }
                            }

                            if !installedSources.isEmpty {
                                Section(header: InlineHeader("Installed")) {
                                    ForEach(installedSources, id: \.self) { source in
                                        InstalledSourceButtonView(installedSource: source)
                                    }
                                }
                            }

                            if !filteredAvailableSources.isEmpty {
                                Section(header: InlineHeader("Catalog")) {
                                    ForEach(filteredAvailableSources, id: \.self) { availableSource in
                                        if !installedSources.contains(where: {
                                            availableSource.name == $0.name &&
                                                availableSource.listId == $0.listId &&
                                                availableSource.author == $0.author
                                        }) {
                                            SourceCatalogButtonView(availableSource: availableSource)
                                        }
                                    }
                                }
                            }
                        }
                        .conditionalId(UUID())
                        .listStyle(.insetGrouped)
                    }
                }
                .sheet(isPresented: $navModel.showSourceSettings) {
                    SourceSettingsView()
                        .environmentObject(navModel)
                }
                .onAppear {
                    viewTask = Task {
                        await sourceManager.fetchSourcesFromUrl()
                        filteredAvailableSources = sourceManager.availableSources.filter { availableSource in
                            !installedSources.contains(where: {
                                availableSource.name == $0.name &&
                                    availableSource.listId == $0.listId &&
                                    availableSource.author == $0.author
                            })
                        }

                        filteredUpdatedSources = sourceManager.fetchUpdatedSources(installedSources: installedSources)
                        checkedForSources = true
                    }
                }
                .onDisappear {
                    viewTask?.cancel()
                }
                .onChange(of: searchText) { _ in
                    sourcePredicate = searchText.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
                }
                .onReceive(installedSources.publisher.count()) { _ in
                    filteredAvailableSources = sourceManager.availableSources.filter { availableSource in
                        let sourceExists = installedSources.contains(where: {
                            availableSource.name == $0.name &&
                                availableSource.listId == $0.listId &&
                                availableSource.author == $0.author
                        })

                        if searchText.isEmpty {
                            return !sourceExists
                        } else {
                            return !sourceExists && availableSource.name.lowercased().contains(searchText.lowercased())
                        }
                    }

                    filteredUpdatedSources = sourceManager.fetchUpdatedSources(installedSources: installedSources).filter {
                        searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
                    }
                }
                .navigationTitle("Sources")
                .navigationSearchBar {
                    SearchBar("Search", text: $searchText, isEditing: $isEditingSearch, onCommit: {
                        isSearching = true
                    })
                    .showsCancelButton(isEditingSearch || isSearching)
                    .onCancel {
                        searchText = ""
                        isSearching = false
                    }
                }
                .introspectSearchController { searchController in
                    searchController.searchBar.autocorrectionType = autocorrectSearch ? .default : .no
                    searchController.searchBar.autocapitalizationType = autocorrectSearch ? .sentences : .none
                }
            }
        }
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView()
    }
}

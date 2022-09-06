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
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    @EnvironmentObject var sourceManager: SourceManager
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    @State private var checkedForSources = false
    @State private var isEditing = false

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
                    } else if sources.isEmpty, sourceManager.availableSources.isEmpty {
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
                                        InstalledSourceView(installedSource: source)
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

                        var updatedSources: [SourceJson] = []
                        for source in installedSources {
                            if let availableSource = sourceManager.availableSources.first(where: {
                                source.listId == $0.listId && source.name == $0.name && source.author == $0.author
                            }),
                                availableSource.version > source.version
                            {
                                updatedSources.append(availableSource)
                            }
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
                    SearchBar("Search", text: $searchText, isEditing: $isEditing)
                        .showsCancelButton(isEditing)
                        .onCancel {
                            searchText = ""
                        }
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

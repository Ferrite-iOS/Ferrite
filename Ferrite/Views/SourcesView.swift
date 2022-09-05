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

    private var updatedSources: [SourceJson] {
        var tempSources: [SourceJson] = []

        for source in sources {
            guard let availableSource = sourceManager.availableSources.first(where: {
                source.listId == $0.listId && source.name == $0.name && source.author == $0.author
            }) else {
                continue
            }

            if availableSource.version > source.version {
                tempSources.append(availableSource)
            }
        }

        return tempSources
    }

    @State private var checkedForSources = false
    @State private var isEditing = false

    @State private var viewTask: Task<Void, Never>? = nil
    @State private var searchText: String = ""
    @State private var filteredUpdatedSources: [SourceJson] = []
    @State private var filteredAvailableSources: [SourceJson] = []

    var body: some View {
        NavView {
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

                        if !sources.isEmpty {
                            Section(header: InlineHeader("Installed")) {
                                ForEach(sources, id: \.self) { source in
                                    InstalledSourceView(installedSource: source)
                                }
                            }
                        }

                        if !filteredAvailableSources.isEmpty {
                            Section(header: InlineHeader("Catalog")) {
                                ForEach(filteredAvailableSources, id: \.self) { availableSource in
                                    SourceCatalogButtonView(availableSource: availableSource)
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
                filteredUpdatedSources = updatedSources
                viewTask = Task {
                    await sourceManager.fetchSourcesFromUrl()
                    filteredAvailableSources = sourceManager.availableSources.filter { availableSource in
                        !sources.contains(
                            where: {
                                availableSource.name == $0.name &&
                                    availableSource.listId == $0.listId &&
                                    availableSource.author == $0.author
                            }
                        )
                    }
                    checkedForSources = true
                }
            }
            .onDisappear {
                viewTask?.cancel()
            }
            .navigationTitle("Sources")
            .navigationSearchBar {
                SearchBar("Search", text: $searchText, isEditing: $isEditing)
                    .showsCancelButton(isEditing)
                    .onCancel {
                        searchText = ""
                    }
            }
            .onChange(of: searchText) { _ in
                filteredAvailableSources = sourceManager.availableSources.filter { availableSource in
                    searchText.isEmpty ? true : availableSource.name.lowercased().contains(searchText.lowercased())
                    && !sources.contains(
                        where: {
                            availableSource.name == $0.name &&
                                availableSource.listId == $0.listId &&
                                availableSource.author == $0.author
                        }
                    )
                }
                filteredUpdatedSources = updatedSources.filter {
                    searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
                }
                if #available(iOS 15.0, *) {
                    if searchText.isEmpty {
                        sources.nsPredicate = nil
                    } else {
                        sources.nsPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
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

//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct SourcesView: View {
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

    var body: some View {
        NavView {
            List {
                if !updatedSources.isEmpty {
                    Section("Updates") {
                        ForEach(updatedSources, id: \.self) { source in
                            SourceUpdateButtonView(updatedSource: source)
                        }
                    }
                }

                if !sources.isEmpty {
                    Section("Installed") {
                        ForEach(sources, id: \.self) { source in
                            InstalledSourceView(installedSource: source)
                        }
                        .sheet(isPresented: $navModel.showSourceSettings) {
                            SourceSettingsView()
                        }
                    }
                }

                if sourceManager.availableSources.contains(where: { availableSource in
                    !sources.contains(
                        where: {
                            availableSource.name == $0.name &&
                            availableSource.listId == $0.listId &&
                            availableSource.author == $0.author
                        }
                    )
                }) {
                    Section("Catalog") {
                        ForEach(sourceManager.availableSources, id: \.self) { availableSource in
                            if !sources.contains(
                                where: {
                                    availableSource.name == $0.name &&
                                    availableSource.listId == $0.listId &&
                                    availableSource.author == $0.author
                                }
                            ) {
                                SourceCatalogButtonView(availableSource: availableSource)
                            }
                        }
                    }
                }
            }
            .task {
                await sourceManager.fetchSourcesFromUrl()
            }
            .navigationTitle("Sources")
        }
    }
}

struct SourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesView()
    }
}

//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct SourceListView: View {
    @EnvironmentObject var sourceManager: SourceManager

    let backgroundContext = PersistenceController.shared.backgroundContext

    @FetchRequest(
        entity: Source.entity(),
        sortDescriptors: []
    ) var sources: FetchedResults<Source>

    @State private var availableSourceLength = 0

    var body: some View {
        NavView {
            List {
                if !sources.isEmpty {
                    Section("Installed") {
                        ForEach(sources, id: \.self) { source in
                            Toggle(isOn: Binding<Bool>(
                                get: { source.enabled },
                                set: {
                                    source.enabled = $0
                                    PersistenceController.shared.save()
                                }
                            )) {
                                Text(source.name)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                if let source = sources[safe: index] {
                                    PersistenceController.shared.delete(source, context: backgroundContext)
                                }
                            }
                        }
                    }
                }

                if sourceManager.availableSources.contains(where: { avail in
                    !sources.contains(where: { avail.name == $0.name })
                }) {
                    Section("Catalog") {
                        ForEach(sourceManager.availableSources, id: \.self) { availableSource in
                            if !sources.contains(where: { availableSource.name == $0.name }) {
                                HStack {
                                    Text(availableSource.name)

                                    Spacer()

                                    Button("Install") {
                                        sourceManager.installSource(sourceJson: availableSource)
                                    }
                                }
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

struct SourceListView_Previews: PreviewProvider {
    static var previews: some View {
        SourceListView()
    }
}

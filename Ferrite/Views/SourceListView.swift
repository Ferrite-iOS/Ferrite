//
//  SourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/24/22.
//

import SwiftUI

struct SourceListView: View {
    @EnvironmentObject var sourceManager: SourceManager
    @EnvironmentObject var navModel: NavigationViewModel

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
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(source.name)
                                        Text("v\(source.version)")
                                            .foregroundColor(.secondary)
                                    }

                                    Text("by \(source.author ?? "Unknown")")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contextMenu {
                                Button {
                                    navModel.selectedSource = source
                                    navModel.showSourceSettings.toggle()
                                } label: {
                                    Text("Settings")
                                    Image(systemName: "gear")
                                }

                                Button {
                                    PersistenceController.shared.delete(source, context: backgroundContext)
                                } label: {
                                    Text("Remove")
                                    Image(systemName: "trash")
                                }
                            }
                        }
                        .sheet(isPresented: $navModel.showSourceSettings) {
                            SourceSettingsView()
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
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text(availableSource.name)
                                            Text("v\(availableSource.version)")
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text("by \(availableSource.author ?? "Unknown")")
                                            .foregroundColor(.secondary)
                                    }

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

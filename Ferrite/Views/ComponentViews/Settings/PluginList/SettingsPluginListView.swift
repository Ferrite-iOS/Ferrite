//
//  SettingsSourceListView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct SettingsPluginListView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel

    @FetchRequest(
        entity: PluginList.entity(),
        sortDescriptors: []
    ) var pluginLists: FetchedResults<PluginList>

    @State private var presentEditSheet = false

    var body: some View {
        ZStack {
            if pluginLists.isEmpty {
                EmptyInstructionView(title: "No Lists", message: "Add a source list using the + button in the top-right")
            } else {
                List {
                    ForEach(pluginLists, id: \.self) { pluginList in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(pluginList.name)

                            Group {
                                Text(pluginList.author)

                                Text("ID: \(pluginList.id)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                navModel.selectedPluginList = pluginList
                                presentEditSheet.toggle()
                            } label: {
                                Text("Edit")
                                Image(systemName: "pencil")
                            }

                            if #available(iOS 15.0, *) {
                                Button(role: .destructive) {
                                    PersistenceController.shared.delete(pluginList, context: backgroundContext)
                                } label: {
                                    Text("Remove")
                                    Image(systemName: "trash")
                                }
                            } else {
                                Button {
                                    PersistenceController.shared.delete(pluginList, context: backgroundContext)
                                } label: {
                                    Text("Remove")
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            if let list = pluginLists[safe: index] {
                                PersistenceController.shared.delete(list, context: backgroundContext)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .inlinedList(inset: -20)
            }
        }
        .sheet(isPresented: $presentEditSheet) {
            if #available(iOS 16, *) {
                PluginListEditorView()
                    .presentationDetents([.medium])
            } else {
                PluginListEditorView()
                    .environmentObject(navModel)
            }
        }
        .navigationTitle("Plugin Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    navModel.selectedPluginList = nil
                    presentEditSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct SettingsPluginListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPluginListView()
    }
}

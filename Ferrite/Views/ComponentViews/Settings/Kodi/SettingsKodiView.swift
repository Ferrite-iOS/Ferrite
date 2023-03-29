//
//  SettingsKodiView.swift
//  Ferrite
//
//  Created by Brian Dashore on 3/4/23.
//

import SwiftUI

struct SettingsKodiView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel

    var kodiServers: FetchedResults<KodiServer>

    @State private var presentEditSheet = false

    var body: some View {
        List {
            Section(header: InlineHeader("Description")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kodi is an external application that is used to manage a local media library and playback.")

                    Link("Website", destination: URL(string: "https://kodi.tv")!)
                }
            }

            Section(
                header: InlineHeader("Servers"),
                footer: Text("Edit a server by holding it and accessing the context menu")
            ) {
                if kodiServers.isEmpty {
                    Text("Add a server using the + button in the top-right")
                } else {
                    ForEach(kodiServers, id: \.self) { server in
                        KodiServerView(server: server)
                            .contextMenu {
                                Button {
                                    navModel.selectedKodiServer = server
                                    presentEditSheet.toggle()
                                } label: {
                                    Text("Edit")
                                    Image(systemName: "pencil")
                                }

                                Button(role: .destructive) {
                                    PersistenceController.shared.delete(server, context: backgroundContext)
                                } label: {
                                    Text("Remove")
                                    Image(systemName: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            if let server = kodiServers[safe: index] {
                                PersistenceController.shared.delete(server, context: backgroundContext)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $presentEditSheet) {
            KodiEditorView()
        }
        .navigationTitle("Kodi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    navModel.selectedKodiServer = nil
                    presentEditSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

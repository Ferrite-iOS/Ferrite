//
//  SettingsSourceUrlView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/25/22.
//

import SwiftUI

struct SettingsSourceListView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @FetchRequest(
        entity: SourceList.entity(),
        sortDescriptors: []
    ) var sourceLists: FetchedResults<SourceList>

    @State private var presentSourceSheet = false

    var body: some View {
        List {
            ForEach(sourceLists, id: \.self) { sourceList in
                VStack(alignment: .leading, spacing: 5) {
                    Text(sourceList.name)
                    Text("ID: \(sourceList.id)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    if let sourceUrl = sourceLists[safe: index] {
                        PersistenceController.shared.delete(sourceUrl, context: backgroundContext)
                    }
                }
            }
        }
        .sheet(isPresented: $presentSourceSheet) {
            if #available(iOS 16, *) {
                SourceListEditorView()
                    .presentationDetents([.medium])
            } else {
                SourceListEditorView()
            }
        }
        .navigationTitle("Source lists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    presentSourceSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct SettingsSourceListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSourceListView()
    }
}

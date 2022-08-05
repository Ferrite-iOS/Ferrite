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
    ) var sourceUrls: FetchedResults<SourceList>

    @State private var presentSourceSheet = false

    var body: some View {
        List {
            ForEach(sourceUrls, id: \.self) { sourceUrl in
                VStack(alignment: .leading, spacing: 5) {
                    Text(sourceUrl.name)
                    Text("ID: \(sourceUrl.id)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    if let sourceUrl = sourceUrls[safe: index] {
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

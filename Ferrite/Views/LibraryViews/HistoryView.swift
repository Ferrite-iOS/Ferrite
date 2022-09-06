//
//  HistoryView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var navModel: NavigationViewModel

    let backgroundContext = PersistenceController.shared.backgroundContext

    var history: FetchedResults<History>
    var formatter: DateFormatter = .init()

    @State private var historyIndex = 0

    init(history: FetchedResults<History>) {
        self.history = history

        formatter.dateStyle = .medium
        formatter.timeStyle = .none
    }

    func groupedEntries(_ result: FetchedResults<History>) -> [[History]] {
        Dictionary(grouping: result) { (element: History) in
            element.dateString ?? ""
        }.values.sorted { $0[0].date ?? Date() > $1[0].date ?? Date() }
    }

    var body: some View {
        if !history.isEmpty {
            List {
                ForEach(groupedEntries(history), id: \.self) { (section: [History]) in
                    Section(header: Text(formatter.string(from: section[0].date ?? Date()))) {
                        ForEach(section, id: \.self) { history in
                            ForEach(history.entryArray) { entry in
                                HistoryButtonView(entry: entry)
                            }
                            .onDelete { offsets in
                                removeEntry(at: offsets, from: history)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    func removeEntry(at offsets: IndexSet, from history: History) {
        for index in offsets {
            if let entry = history.entryArray[safe: index] {
                history.removeFromEntries(entry)
                PersistenceController.shared.delete(entry, context: backgroundContext)
            }

            if history.entryArray.isEmpty {
                PersistenceController.shared.delete(history, context: backgroundContext)
            }
        }
    }
}

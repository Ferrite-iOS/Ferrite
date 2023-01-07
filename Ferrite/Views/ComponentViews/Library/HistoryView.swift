//
//  HistoryView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/2/22.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var navModel: NavigationViewModel

    var history: FetchedResults<History>

    @Binding var searchText: String

    @State private var historyPredicate: NSPredicate?

    var body: some View {
        DynamicFetchRequest(predicate: historyPredicate) { (allEntries: FetchedResults<HistoryEntry>) in
            List {
                if !history.isEmpty {
                    ForEach(groupedHistory(history), id: \.self) { historyGroup in
                        HistorySectionView(allEntries: allEntries, historyGroup: historyGroup)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .onAppear {
            applyPredicate()
        }
        .onChange(of: searchText) { _ in
            applyPredicate()
        }
    }

    func applyPredicate() {
        if searchText.isEmpty {
            historyPredicate = nil
        } else {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText.lowercased())
            let subNamePredicate = NSPredicate(format: "subName CONTAINS[cd] %@", searchText.lowercased())
            historyPredicate = NSCompoundPredicate(type: .or, subpredicates: [namePredicate, subNamePredicate])
        }
    }

    func groupedHistory(_ result: FetchedResults<History>) -> [[History]] {
        Dictionary(grouping: result) { (element: History) in
            element.dateString ?? ""
        }
        .values
        .sorted { $0[0].date ?? Date() > $1[0].date ?? Date() }
    }
}

struct HistorySectionView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    var formatter: DateFormatter = .init()
    var allEntries: FetchedResults<HistoryEntry>
    var historyGroup: [History]

    init(allEntries: FetchedResults<HistoryEntry>, historyGroup: [History]) {
        self.allEntries = allEntries
        self.historyGroup = historyGroup

        formatter.dateStyle = .medium
        formatter.timeStyle = .none
    }

    var body: some View {
        if compareGroup(historyGroup) > 0 {
            Section(header: Text(formatter.string(from: historyGroup[0].date ?? Date()))) {
                ForEach(historyGroup, id: \.self) { history in
                    ForEach(history.entryArray.filter { allEntries.contains($0) }, id: \.self) { entry in
                        HistoryButtonView(entry: entry)
                    }
                    .onDelete { offsets in
                        removeEntry(at: offsets, from: history)
                    }
                }
            }
        }
    }

    func compareGroup(_ group: [History]) -> Int {
        var totalCount = 0
        for history in group {
            totalCount += history.entryArray.reduce(0) { result, item in
                result + (allEntries.contains { $0.name == item.name || (item.subName.map { !$0.isEmpty } ?? false && $0.subName == item.subName) } ? 1 : 0)
            }
        }

        return totalCount
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

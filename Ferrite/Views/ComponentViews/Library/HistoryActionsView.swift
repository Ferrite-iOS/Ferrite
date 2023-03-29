//
//  HistoryActionsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/7/22.
//

import SwiftUI

struct HistoryActionsView: View {
    @EnvironmentObject var logManager: LoggingManager

    @State private var showActionSheet = false

    var body: some View {
        Button("Clear") {
            showActionSheet.toggle()
        }
        .tint(.red)
        .confirmationDialog(
            "Clear watch history",
            isPresented: $showActionSheet,
            titleVisibility: .visible
        ) {
            Button("Past day", role: .destructive) {
                deleteHistory(.day)
            }
            Button("Past week", role: .destructive) {
                deleteHistory(.week)
            }
            Button("Past month", role: .destructive) {
                deleteHistory(.month)
            }
            Button("All time", role: .destructive) {
                deleteHistory(.allTime)
            }
        } message: {
            Text("This is an irreversible action!")
        }
    }

    func deleteHistory(_ deleteRange: HistoryDeleteRange) {
        do {
            try PersistenceController.shared.batchDeleteHistory(range: deleteRange)
        } catch {
            logManager.error("History delete error: \(error)")
        }
    }
}

struct HistoryActionsView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryActionsView()
    }
}

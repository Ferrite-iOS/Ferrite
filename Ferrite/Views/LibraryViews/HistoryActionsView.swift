//
//  HistoryActionsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 9/7/22.
//

import SwiftUI

struct HistoryActionsView: View {
    @EnvironmentObject var toastModel: ToastViewModel

    @State private var showActionSheet = false

    var body: some View {
        Button("Clear") {
            showActionSheet.toggle()
        }
        .dynamicAccentColor(.red)
        .dynamicActionSheet(
            isPresented: $showActionSheet,
            title: "Clear watch history",
            message: "This is an irreversible action!",
            buttons: [
                AlertButton("Past day", role: .destructive) {
                    deleteHistory(.day)
                },
                AlertButton("Past week", role: .destructive) {
                    deleteHistory(.week)
                },
                AlertButton("Past month", role: .destructive) {
                    deleteHistory(.month)
                },
                AlertButton("All time", role: .destructive) {
                    deleteHistory(.allTime)
                }
            ]
        )
    }

    func deleteHistory(_ deleteRange: HistoryDeleteRange) {
        do {
            try PersistenceController.shared.batchDeleteHistory(range: deleteRange)
        } catch {
            toastModel.updateToastDescription("History delete error: \(error)")
        }
    }
}

struct HistoryActionsView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryActionsView()
    }
}

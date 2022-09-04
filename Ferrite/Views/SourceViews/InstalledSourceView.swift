//
//  InstalledSourceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/5/22.
//

import SwiftUI

struct InstalledSourceView: View {
    let backgroundContext = PersistenceController.shared.backgroundContext

    @EnvironmentObject var navModel: NavigationViewModel

    @ObservedObject var installedSource: Source

    var body: some View {
        Toggle(isOn: Binding<Bool>(
            get: { installedSource.enabled },
            set: {
                installedSource.enabled = $0
                PersistenceController.shared.save()
            }
        )) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(installedSource.name)
                    Text("v\(installedSource.version)")
                        .foregroundColor(.secondary)
                }

                Text("by \(installedSource.author)")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .contextMenu {
            Button {
                navModel.selectedSource = installedSource
                navModel.showSourceSettings.toggle()
            } label: {
                Text("Settings")
                Image(systemName: "gear")
            }

            if #available(iOS 15.0, *) {
                Button(role: .destructive) {
                    PersistenceController.shared.delete(installedSource, context: backgroundContext)
                } label: {
                    Text("Remove")
                    Image(systemName: "trash")
                }
            } else {
                Button {
                    PersistenceController.shared.delete(installedSource, context: backgroundContext)
                } label: {
                    Text("Remove")
                    Image(systemName: "trash")
                }
            }
        }
    }
}

//
//  DebridCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/31/22.
//

import SwiftUI

struct DebridCloudView: View {
    @EnvironmentObject var debridManager: DebridManager

    @Binding var searchText: String

    var body: some View {
        List {
            switch debridManager.selectedDebridType {
            case .realDebrid:
                RealDebridCloudView(searchText: $searchText)
            case .premiumize:
                PremiumizeCloudView(searchText: $searchText)
            case .allDebrid:
                AllDebridCloudView(searchText: $searchText)
            case .none:
                EmptyView()
            }
        }
        .listStyle(.plain)
        .task {
            await debridManager.fetchDebridCloud()
        }
        .refreshable {
            await debridManager.fetchDebridCloud(bypassTTL: true)
        }
        .onChange(of: debridManager.selectedDebridType) { newType in
            if newType != nil {
                Task {
                    await debridManager.fetchDebridCloud()
                }
            }
        }
    }
}

//
//  DebridCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/31/22.
//

import SwiftUI
import SwiftUIX

struct DebridCloudView: View {
    @EnvironmentObject var debridManager: DebridManager

    var body: some View {
        NavView {
            VStack {
                List {
                    switch debridManager.selectedDebridType {
                    case .realDebrid:
                        RealDebridCloudView()
                    case .premiumize:
                        PremiumizeCloudView()
                    case .allDebrid, .none:
                        EmptyView()
                    }
                }
                .inlinedList()
                .listStyle(.grouped)
            }
        }
    }
}

struct DebridCloudView_Previews: PreviewProvider {
    static var previews: some View {
        DebridCloudView()
    }
}

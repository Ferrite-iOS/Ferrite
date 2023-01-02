//
//  DebridCloudView.swift
//  Ferrite
//
//  Created by Brian Dashore on 12/31/22.
//

import SwiftUI

struct DebridCloudView: View {
    @EnvironmentObject var debridManager: DebridManager

    var body: some View {
        List {
            switch debridManager.selectedDebridType {
            case .realDebrid:
                RealDebridCloudView()
            case .allDebrid, .premiumize, .none:
                EmptyView()
            }
        }
        .inlinedList()
        .listStyle(.insetGrouped)
    }
}

struct DebridCloudView_Previews: PreviewProvider {
    static var previews: some View {
        DebridCloudView()
    }
}

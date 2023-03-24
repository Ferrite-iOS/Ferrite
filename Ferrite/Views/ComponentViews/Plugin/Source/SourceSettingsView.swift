//
//  SourceSettingsView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/4/22.
//

import SwiftUI

struct SourceSettingsView: View {
    @ObservedObject var selectedSource: Source

    var body: some View {
        if selectedSource.dynamicBaseUrl {
            SourceSettingsBaseUrlView(selectedSource: selectedSource)
        }

        if let sourceApi = selectedSource.api,
           sourceApi.clientId?.dynamic ?? false || sourceApi.clientSecret?.dynamic ?? false
        {
            SourceSettingsApiView(selectedSourceApi: sourceApi)
        }

        SourceSettingsMethodView(selectedSource: selectedSource)
    }
}

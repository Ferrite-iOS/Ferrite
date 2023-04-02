//
//  PluginInfoAboutView.swift
//  Ferrite
//
//  Created by Brian Dashore on 4/2/23.
//

import SwiftUI

struct PluginInfoAboutView<P: Plugin>: View {
    @ObservedObject var selectedPlugin: P

    var body: some View {
        Section(header: InlineHeader("Description")) {
            VStack(alignment: .leading, spacing: 10) {
                if let pluginAbout = selectedPlugin.about {
                    if pluginAbout.last == "\n" {
                        Text(pluginAbout.dropLast())
                    } else {
                        Text(pluginAbout)
                    }
                }

                if let pluginWebsite = selectedPlugin.website {
                    Link("Website", destination: URL(string: pluginWebsite) ?? URL(string: "https://kingbri.dev/ferrite")!)
                }
            }
        }
    }
}

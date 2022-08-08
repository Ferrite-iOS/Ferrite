//
//  AboutView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Image("AppImage")
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(25)

            Text("Ferrite is a free and open source application developed by kingbri under the GNU-GPLv3 license.")
                .padding()

            List {
                ListRowTextView(leftText: "Version", rightText: UIApplication.shared.appVersion)
                ListRowTextView(leftText: "Build number", rightText: UIApplication.shared.appBuild)
                ListRowTextView(leftText: "Build type", rightText: UIApplication.shared.buildType)
                ListRowLinkView(text: "GitHub repository", link: "https://github.com/bdashore3/Ferrite")
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

//
//  AboutView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/26/22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                ListRowTextView(leftText: "Version", rightText: UIApplication.shared.appVersion)
                ListRowTextView(leftText: "Build number", rightText: UIApplication.shared.appBuild)
                ListRowTextView(leftText: "Build type", rightText: UIApplication.shared.buildType)
                ListRowLinkView(text: "Discord server", link: "https://discord.gg/sYQxnuD7Fj")
                ListRowLinkView(text: "GitHub repository", link: "https://github.com/bdashore3/Ferrite")
            } header: {
                VStack(alignment: .center) {
                    Image("AppImage")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 100*0.225, style: .continuous))
                        .padding(.top, 24)

                    Text("Ferrite is a free and open source application developed by kingbri under the GNU-GPLv3 license.")
                        .textCase(.none)
                        .foregroundColor(.label)
                        .font(.body)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

//
//  TestHostingView.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/13/23.
//

import SwiftUI

struct TestHostingView: View {
    @State private var textName = "First"
    @State private var secondTextName = "First"
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Menu {
                    Picker("", selection: $textName) {
                        Text("First").tag("First")
                        Text("Second").tag("Second")
                        Text("Third").tag("Third")
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(textName)
                            .opacity(0.6)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.tertiaryLabel)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .font(.caption, weight: .bold)
                    .background(Capsule().foregroundColor(.secondarySystemFill))
                }
                .id(textName)
                .transaction {
                    $0.animation = .none
                }

                Menu {
                    Picker("", selection: $secondTextName) {
                        Text("First").tag("First")
                        Text("Second").tag("Second")
                        Text("Third").tag("Third")
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(secondTextName)
                            .opacity(0.6)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.tertiaryLabel)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .font(.caption, weight: .bold)
                    .background(Capsule().foregroundColor(.secondarySystemFill))
                }
                .id(secondTextName)
                .transaction {
                    $0.animation = .none
                }
            }
            .padding(.horizontal, 18)
        }
    }
}

struct TestHostingView_Previews: PreviewProvider {
    static var previews: some View {
        TestHostingView()
    }
}

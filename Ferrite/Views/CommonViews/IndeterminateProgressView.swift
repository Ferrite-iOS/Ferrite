//
//  IndeterminateProgressView.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/26/22.
//
//  Inspired by https://daringsnowball.net/articles/indeterminate-linear-progress-view/
//

import SwiftUI

struct IndeterminateProgressView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { reader in
            Rectangle()
                .foregroundColor(.gray.opacity(0.15))
                .overlay(
                    Rectangle()
                        .foregroundColor(Color.accentColor)
                        .frame(width: reader.size.width * 0.26, height: 6)
                        .clipShape(Capsule())

                        .offset(x: -reader.size.width * 0.6, y: 0)
                        .offset(x: reader.size.width * 1.2 * self.offset, y: 0)
                        .animation(.default.repeatForever().speed(0.5), value: self.offset)
                        .backport.onAppear {
                            withAnimation {
                                self.offset = 1
                            }
                        }
                )
                .clipShape(Capsule())
        }
        .frame(height: 4, alignment: .center)
    }
}

struct IndeterminateProgressView_Previews: PreviewProvider {
    static var previews: some View {
        IndeterminateProgressView()
    }
}

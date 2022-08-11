//
//  DefaultActionsPickerViews.swift
//  Ferrite
//
//  Created by Brian Dashore on 8/11/22.
//

import SwiftUI

struct MagnetActionPickerView: View {
    @AppStorage("Actions.DefaultMagnet") var defaultMagnetAction: DefaultMagnetActionType = .none

    var body: some View {
        List {
            Picker(selection: $defaultMagnetAction, label: EmptyView()) {
                Text("Let me choose")
                    .tag(DefaultMagnetActionType.none)
                Text("Open in Webtor")
                    .tag(DefaultMagnetActionType.webtor)
                Text("Share magnet link")
                    .tag(DefaultMagnetActionType.shareMagnet)
            }
        }
        .pickerStyle(.inline)
        .listStyle(.insetGrouped)
        .navigationTitle("Default magnet action")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DebridActionPickerView: View {
    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none

    var body: some View {
        List {
            Picker(selection: $defaultDebridAction, label: EmptyView()) {
                Text("Let me choose")
                    .tag(DefaultDebridActionType.none)
                Text("Open in Outplayer")
                    .tag(DefaultDebridActionType.outplayer)
                Text("Open in VLC")
                    .tag(DefaultDebridActionType.vlc)
                Text("Open in Infuse")
                    .tag(DefaultDebridActionType.infuse)
                Text("Share download link")
                    .tag(DefaultDebridActionType.shareDownload)
            }
        }
        .pickerStyle(.inline)
        .listStyle(.insetGrouped)
        .navigationTitle("Default debrid action")
        .navigationBarTitleDisplayMode(.inline)
    }
}

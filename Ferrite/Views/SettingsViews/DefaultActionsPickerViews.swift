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
            ForEach(DefaultMagnetActionType.allCases, id: \.self) { action in
                Button {
                    defaultMagnetAction = action
                } label: {
                    HStack {
                        Text(fetchPickerChoiceName(choice: action))
                        Spacer()
                        if action == defaultMagnetAction {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .dynamicAccentColor(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Default magnet action")
        .navigationBarTitleDisplayMode(.inline)
    }

    func fetchPickerChoiceName(choice: DefaultMagnetActionType) -> String {
        switch choice {
        case .none:
            return "Let me choose"
        case .webtor:
            return "Open in Webtor"
        case .shareMagnet:
            return "Share magnet link"
        }
    }
}

struct DebridActionPickerView: View {
    @AppStorage("Actions.DefaultDebrid") var defaultDebridAction: DefaultDebridActionType = .none

    var body: some View {
        List {
            ForEach(DefaultDebridActionType.allCases, id: \.self) { action in
                Button {
                    defaultDebridAction = action
                } label: {
                    HStack {
                        Text(fetchPickerChoiceName(choice: action))
                        Spacer()
                        if action == defaultDebridAction {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .dynamicAccentColor(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Default debrid action")
        .navigationBarTitleDisplayMode(.inline)
    }

    func fetchPickerChoiceName(choice: DefaultDebridActionType) -> String {
        switch choice {
        case .none:
            return "Let me choose"
        case .outplayer:
            return "Open in Outplayer"
        case .vlc:
            return "Open in VLC"
        case .infuse:
            return "Open in Infuse"
        case .shareDownload:
            return "Share download link"
        }
    }
}

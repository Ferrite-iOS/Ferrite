//
//  MagnetChoiceView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/20/22.
//

import SwiftUI

struct ActionChoiceView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var scrapingModel: ScrapingViewModel
    @EnvironmentObject var debridManager: DebridManager
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var pluginManager: PluginManager

    @FetchRequest(
        entity: Action.entity(),
        sortDescriptors: []
    ) var actions: FetchedResults<Action>

    @FetchRequest(
        entity: KodiServer.entity(),
        sortDescriptors: []
    ) var kodiServers: FetchedResults<KodiServer>

    @State private var showLinkCopyAlert = false
    @State private var showMagnetCopyAlert = false

    var body: some View {
        NavView {
            Form {
                Section(header: InlineHeader("Now Playing")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(navModel.selectedTitle)
                            .font(.callout)
                            .lineLimit(navModel.selectedBatchTitle.isEmpty ? .max : 1)

                        if !navModel.selectedBatchTitle.isEmpty {
                            Text(navModel.selectedBatchTitle)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }

                if !debridManager.downloadUrl.isEmpty {
                    Section(header: InlineHeader("Debrid options")) {
                        ForEach(actions, id: \.id) { action in
                            if action.requires.contains(ActionRequirement.debrid.rawValue) {
                                ListRowButtonView(action.name, systemImage: "arrow.up.forward.app.fill") {
                                    pluginManager.runDeeplinkAction(action, urlString: debridManager.downloadUrl)
                                }
                            }
                        }

                        if !kodiServers.isEmpty {
                            DisclosureGroup("Open in Kodi", isExpanded: $navModel.kodiExpanded) {
                                ForEach(kodiServers, id: \.self) { server in
                                    Button {
                                        Task {
                                            await pluginManager.sendToKodi(urlString: debridManager.downloadUrl, server: server)
                                        }
                                    } label: {
                                        KodiServerView(server: server)
                                    }
                                    .tint(.primary)
                                }
                            }
                            .tint(.secondary)
                        }

                        ListRowButtonView("Copy download URL", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = debridManager.downloadUrl
                            showLinkCopyAlert.toggle()
                        }
                        .alert("Copied", isPresented: $showLinkCopyAlert) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("Download link copied successfully")
                        }

                        ListRowButtonView("Share download URL", systemImage: "square.and.arrow.up.fill") {
                            if let url = URL(string: debridManager.downloadUrl) {
                                navModel.activityItems = [url]
                                navModel.showLocalActivitySheet.toggle()
                            }
                        }
                    }
                }

                if !navModel.resultFromCloud {
                    Section(header: InlineHeader("Magnet options")) {
                        ForEach(actions, id: \.id) { action in
                            if action.requires.contains(ActionRequirement.magnet.rawValue) {
                                ListRowButtonView(action.name, systemImage: "arrow.up.forward.app.fill") {
                                    pluginManager.runDeeplinkAction(action, urlString: navModel.selectedMagnet?.link)
                                }
                            }
                        }

                        ListRowButtonView("Copy magnet", systemImage: "doc.on.doc.fill") {
                            UIPasteboard.general.string = navModel.selectedMagnet?.link
                            showMagnetCopyAlert.toggle()
                        }
                        .alert("Copied", isPresented: $showMagnetCopyAlert) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("Magnet link copied successfully")
                        }

                        ListRowButtonView("Share magnet", systemImage: "square.and.arrow.up.fill") {
                            if let magnetLink = navModel.selectedMagnet?.link,
                               let url = URL(string: magnetLink)
                            {
                                navModel.activityItems = [url]
                                navModel.showLocalActivitySheet.toggle()
                            }
                        }
                    }
                }
            }
            .tint(.primary)
            .sheet(isPresented: $navModel.showLocalActivitySheet) {
                // TODO: Fix share sheet
                if #available(iOS 16, *) {
                    ShareSheet(activityItems: navModel.activityItems)
                        .presentationDetents([.medium, .large])
                } else {
                    ShareSheet(activityItems: navModel.activityItems)
                }
            }
            .alert("Action successful", isPresented: $pluginManager.showActionSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pluginManager.actionSuccessAlertMessage)
            }
            .alert("Action error", isPresented: $pluginManager.showActionErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pluginManager.actionErrorAlertMessage)
            }
            .onDisappear {
                debridManager.downloadUrl = ""
                navModel.selectedTitle = ""
                navModel.selectedBatchTitle = ""
                navModel.resultFromCloud = false
            }
            .navigationTitle("Link actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        debridManager.downloadUrl = ""
                        navModel.selectedTitle = ""
                        navModel.selectedBatchTitle = ""

                        dismiss()
                    }
                }
            }
        }
    }
}

struct ActionChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        ActionChoiceView()
    }
}

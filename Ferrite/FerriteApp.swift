//
//  FerriteApp.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/1/22.
//

import SwiftUI

@main
struct FerriteApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject var scrapingModel: ScrapingViewModel = .init()
    @StateObject var toastModel: ToastViewModel = .init()
    @StateObject var debridManager: DebridManager = .init()
    @StateObject var navModel: NavigationViewModel = .init()
    @StateObject var pluginManager: PluginManager = .init()
    @StateObject var backupManager: BackupManager = .init()

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    scrapingModel.toastModel = toastModel
                    debridManager.toastModel = toastModel
                    pluginManager.toastModel = toastModel
                    backupManager.toastModel = toastModel
                    navModel.toastModel = toastModel
                }
                .environmentObject(debridManager)
                .environmentObject(scrapingModel)
                .environmentObject(toastModel)
                .environmentObject(navModel)
                .environmentObject(pluginManager)
                .environmentObject(backupManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

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
    @StateObject var navigationModel: NavigationViewModel = .init()
    @StateObject var sourceManager: SourceManager = .init()

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    scrapingModel.toastModel = toastModel
                    debridManager.toastModel = toastModel
                    sourceManager.toastModel = toastModel
                }
                .environmentObject(debridManager)
                .environmentObject(scrapingModel)
                .environmentObject(toastModel)
                .environmentObject(navigationModel)
                .environmentObject(sourceManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

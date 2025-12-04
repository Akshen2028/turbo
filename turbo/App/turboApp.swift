//
//  turboApp.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI
import CoreData

@main
struct turboApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

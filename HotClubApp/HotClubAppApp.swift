//
//  HotClubAppApp.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 10/13/25.
//

import SwiftUI
import CoreData

@main
struct HotClubAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  HotClubAppApp.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 10/13/25.
//

import SwiftUI

@main
struct HotClubAppApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
    }
}

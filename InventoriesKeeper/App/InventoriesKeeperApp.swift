//
//  InventoriesKeeperApp.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI

@main
struct InventoriesKeeperApp: App {
    init() {
//        RealmConfig.configure()
        RealmConfig.configure(resetOnLaunch: true)
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

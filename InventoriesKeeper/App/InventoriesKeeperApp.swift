//
//  InventoriesKeeperApp.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI

@main
struct InventoriesKeeperApp: App {
    @StateObject private var session = UserSession()
    
    init() {
//        RealmConfig.configure()
//        RealmConfig.configure(resetOnLaunch: true)
    }

    var body: some Scene {
        WindowGroup {
            if session.isLoggedIn {
                if session.isAdmin {
                    AdminPanelView()
                        .environmentObject(session)
                } else {
                    GamesListView()
                        .environmentObject(session)
                }
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}

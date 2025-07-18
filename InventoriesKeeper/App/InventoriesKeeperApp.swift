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
                    AdminPanelView(vm: AdminPanelViewModel(session: session))
                        .environmentObject(session)
                } else {
                    GamesListView(session: session)
                        .environmentObject(session)
                }
            } else {
                LoginView(session: session)
                    .environmentObject(session)
            }
        }
    }
}

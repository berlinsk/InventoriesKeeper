//
//  AdminPanelViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 14.07.2025.
//

import Foundation
import SwiftUI
import RealmSwift

final class AdminPanelViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var games: [Game] = []

    @Published var showDump = false
    @Published var allInventories: [Inventory] = []
    @Published var allItems: [Item] = []

    @Published var listReloadKey = UUID()

    private let session: UserSession

    init(session: UserSession) {
        self.session = session
    }

    func fetchUsers() {
        let realm = try! Realm()
        users = Array(realm.objects(User.self).freeze())
    }

    func fetchGames() {
        let realm = try! Realm()
        games = Array(realm.objects(Game.self).freeze())
    }

    func loadDumpSnapshot() {
        let realm = try! Realm()
        let invs = realm.objects(Inventory.self).freeze()
        let items = realm.objects(Item.self).freeze()
        self.allInventories = Array(invs)
        self.allItems = Array(items)
    }

    func clearDump() {
        self.allInventories.removeAll()
        self.allItems.removeAll()
    }

    func setShowDump(_ on: Bool) {
        showDump = on
        if on { loadDumpSnapshot() } else { clearDump() }
    }

    private func afterMutationRefresh() {
        fetchUsers()
        fetchGames()
        if showDump {
            loadDumpSnapshot()
        } else {
            clearDump()
        }
        listReloadKey = UUID()
    }

    func deleteUsers(at offsets: IndexSet) {
        for i in offsets {
            deleteUser(users[i])
        }
        afterMutationRefresh()
    }

    private func deleteUser(_ user: User) {
        let isCurrent = (user.id == session.currentUser()?.id)

        let tempSession = UserSession()
        tempSession.user = user
        tempSession.deleteCurrentUser()

        if isCurrent {
            session.logout()
        }
    }
    
    func deleteGames(at offsets: IndexSet) {
        for i in offsets {
            let game = games[i]
            try? GameRepository.delete(game: game)
        }
        afterMutationRefresh()
    }

    func exportUserRealm(user: User) {
        let realmFileURL = FileManager.documentsURL.appendingPathComponent("\(user.username).realm")
        let activityVC = UIActivityViewController(activityItems: [realmFileURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    func confirmAndDeleteAllData() {
        let alert = UIAlertController(
            title: "Delete ALL Data?",
            message: "This will permanently delete all user data and games. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            DispatchQueue.main.async {
                self.users = []
                self.games = []
                self.clearDump()
                self.listReloadKey = UUID()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.deleteAllData()
                DispatchQueue.main.async {
                    self.afterMutationRefresh()
                }
            }
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    private func deleteAllData() {
        let realm = try! Realm()

        let currentId = session.currentUser()?.id
        var removedCurrent = false

        let idsToDelete = realm.objects(User.self)
                               .filter("username != %@", "admin")
                               .map(\.id)

        for id in idsToDelete {
            if let rUser = realm.object(ofType: User.self, forPrimaryKey: id) {
                if id == currentId { removedCurrent = true }
                deleteUser(rUser)
            }
        }
        
        let allGames = Array(realm.objects(Game.self))
        for game in allGames {
            try? GameRepository.delete(game: game)
        }

        if removedCurrent {
            session.logout()
        }
    }

    func logout() {
        session.logout()
    }
}

//
//  AdminPanelViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 14.07.2025.
//

import Foundation
import SwiftUI
import RealmSwift

enum AdminPanelTab: String, CaseIterable, Hashable, Identifiable {
    case dashboard = "Dashboard"
    case subscriptions = "Subscriptions"
    var id: String { rawValue }
}

final class AdminPanelViewModel: ObservableObject {
    @Published var activeTab: AdminPanelTab = .dashboard

    @Published var users: [User] = []
    @Published var games: [Game] = []

    @Published var showDump = false
    @Published var allInventories: [Inventory] = []
    @Published var allItems: [Item] = []

    @Published var listReloadKey = UUID()

    @Published var subscriptions: [ObjectId: [Game]] = [:]

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
        reloadSubscriptions()
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
                self.subscriptions.removeAll()
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

    func reloadSubscriptions() {
        let realm = try! Realm()
        let rUsers = realm.objects(User.self).freeze()
        var map: [ObjectId: [Game]] = [:]
        for u in rUsers {
            var gamesForUser: [Game] = []
            for gid in u.subscribedGames {
                if let g = realm.object(ofType: Game.self, forPrimaryKey: gid)?.freeze() {
                    gamesForUser.append(g)
                }
            }
            gamesForUser.sort { (a, b) in
                if a.isInvalidated && !b.isInvalidated { return false }
                if !a.isInvalidated && b.isInvalidated { return true }
                let at = a.isInvalidated ? "" : a.title
                let bt = b.isInvalidated ? "" : b.title
                return at.localizedCaseInsensitiveCompare(bt) == .orderedAscending
            }
            map[u.id] = gamesForUser
        }
        self.users = Array(rUsers)
        self.subscriptions = map
        listReloadKey = UUID()
    }

    func unsubscribe(userId: ObjectId, from gameId: ObjectId) {
        let realm = try! Realm()
        try! realm.write {
            guard
                let user = realm.object(ofType: User.self, forPrimaryKey: userId),
                let game = realm.object(ofType: Game.self, forPrimaryKey: gameId)
            else { return }
            GameRepository.unsubscribeAndCleanup(user, from: game, in: realm)
        }
        reloadSubscriptions()
    }

    func unsubscribeAll(userId: ObjectId) {
        let realm = try! Realm()
        try! realm.write {
            guard let user = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            let ids = Array(user.subscribedGames)
            for gid in ids {
                if let game = realm.object(ofType: Game.self, forPrimaryKey: gid) {
                    GameRepository.unsubscribeAndCleanup(user, from: game, in: realm)
                }
            }
        }
        reloadSubscriptions()
    }
}

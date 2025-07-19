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

    private let session: UserSession

    init(session: UserSession) {
        self.session = session
    }

    func fetchUsers() {
        let realm = try! Realm()
        let rUsers = realm.objects(User.self)
        users = Array(rUsers)
    }

    func deleteUsers(at offsets: IndexSet) {
        for i in offsets {
            deleteUser(users[i])
        }
        fetchUsers()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.deleteAllData()
                DispatchQueue.main.async {
                    self.users = []
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

        if removedCurrent {
            session.logout()
        }
    }

    func logout() {
        session.logout()
    }
}

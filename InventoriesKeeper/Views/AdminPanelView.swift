//
//  AdminPanelView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI
import RealmSwift

struct AdminPanelView: View {
    @EnvironmentObject var session: UserSession
    @State private var users: [User] = []

    var body: some View {
        NavigationStack {
            List {
                if !users.isEmpty {
                    Section(header: Text("Users")) {
                        ForEach(users, id: \.id) { user in
                            HStack {
                                Text(user.username)
                                Spacer()
                                Button("Export") {
                                    exportUserRealm(user: user)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { i in
                                deleteUser(users[i])
                            }
                            fetchUsers()
                        }
                    }
                } else {
                    Text("No users to display")
                        .foregroundColor(.gray)
                }
            }
            .id(UUID())
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { session.logout() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete ALL Data") {
                        confirmAndDeleteAllData()
                    }
                }
            }
            .onAppear {
                fetchUsers()
            }
        }

    }

    private func fetchUsers() {
        let realm = try! Realm()
        let rUsers = realm.objects(RUser.self)
        users = rUsers.map { User(model: $0) }
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

    private func exportUserRealm(user: User) {
        let realmFileURL = FileManager.documentsURL.appendingPathComponent("\(user.username).realm")

        let activityVC = UIActivityViewController(activityItems: [realmFileURL], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func confirmAndDeleteAllData() {
        let alert = UIAlertController(
            title: "Delete ALL Data?",
            message: "This will permanently delete all user data and games. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            self.users = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                deleteAllData()
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

        let idsToDelete = realm.objects(RUser.self)
                               .filter("username != %@", "admin")
                               .map(\.id)

        users = []

        for id in idsToDelete {
            if let rUser = realm.object(ofType: RUser.self, forPrimaryKey: id) {
                let nameSnapshot = rUser.username
                let user = User(model: rUser)
                if id == currentId { removedCurrent = true }
                deleteUser(user)
            }
        }

        if removedCurrent {
            session.logout()
        }

        users = []
    }
}

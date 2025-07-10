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
    @State private var users: [RUser] = []

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Users")) {
                    ForEach(users, id: \.id) { user in
                        Text(user.username)
                    }
                    .onDelete { idx in
                        idx.forEach { i in
                            deleteUser(users[i])
                        }
                        fetchUsers()
                    }
                }
            }
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
        users = Array(realm.objects(RUser.self))
    }

    private func deleteUser(_ user: RUser) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(user.games)
            realm.delete(user)
        }
    }

    private func confirmAndDeleteAllData() {
        
    }
}

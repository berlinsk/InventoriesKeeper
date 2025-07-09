//
//  AdminPanelView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var session: UserSession
    @State private var users: [String] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(users, id: \.self) { name in
                    Text(name)
                }
                .onDelete { idx in
                    idx.forEach { i in
                        deleteUser(named: users[i])
                    }
                    users = fetchUsers()
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { session.logout() }
                }
            }
            .onAppear { users = fetchUsers() }
        }
    }

    private func fetchUsers() -> [String] {
        UserDefaults.standard.dictionaryRepresentation().keys
            .compactMap { $0.hasPrefix("user_") ? $0.replacingOccurrences(of: "user_", with: "").replacingOccurrences(of: "_password", with: "") : nil }
            .sorted()
    }

    private func deleteUser(named user: String) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "user_\(user)_password")
        let url = FileManager.documentsURL.appendingPathComponent("\(user).realm")
        FileManager.default.removeItemIfExists(at: url)
    }
}

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
        NavigationView {
            List {
                ForEach(users, id: \.self) { user in
                    Text(user)
                }
                .onDelete(perform: deleteUser)
            }
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        session.logout()
                    }
                }
            }
        }
        .onAppear(perform: loadUsers)
    }

    private func loadUsers() {
        let defaults = UserDefaults.standard
        users = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("user_") && $0.hasSuffix("_password") }
            .map { $0.replacingOccurrences(of: "user_", with: "").replacingOccurrences(of: "_password", with: "") }
    }

    private func deleteUser(at offsets: IndexSet) {
        let defaults = UserDefaults.standard
        for index in offsets {
            let user = users[index]
            let key = "user_\(user)_password"
            defaults.removeObject(forKey: key)
            let fileURL = FileManager.documentsURL.appendingPathComponent("\(user).realm")
            FileManager.default.removeItemIfExists(at: fileURL)
        }
        loadUsers()
    }
}

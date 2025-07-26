//
//  AdminPanelView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct AdminPanelView: View {
    @ObservedObject var vm: AdminPanelViewModel

    var body: some View {
        NavigationStack {
            List {
                if !vm.users.isEmpty {
                    Section(header: Text("Users")) {
                        ForEach(vm.users, id: \.id) { user in
                            HStack {
                                Text(user.username)
                                Spacer()
                                Button("Export") {
                                    vm.exportUserRealm(user: user)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .onDelete(perform: vm.deleteUsers)
                    }
                } else {
                    Text("No users to display")
                        .foregroundColor(.gray)
                }
                if !vm.games.isEmpty {
                    Section(header: Text("Games")) {
                        ForEach(vm.games, id: \.id) { game in
                            VStack(alignment: .leading) {
                                Text(game.title).font(.headline)
                                if let details = game.details {
                                    Text(details).font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: vm.deleteGames)
                    }
                } else {
                    Text("No games to display")
                        .foregroundColor(.gray)
                }
            }
            .id(UUID())
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        vm.logout()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete ALL Data") {
                        vm.confirmAndDeleteAllData()
                    }
                }
            }
            .onAppear {
                vm.fetchUsers()
                vm.fetchGames()
            }
        }
    }
}

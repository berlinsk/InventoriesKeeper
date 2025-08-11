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
            VStack(spacing: 12) {
                Picker("Mode", selection: $vm.activeTab) {
                    Text("Dashboard").tag(AdminPanelTab.dashboard)
                    Text("Subscriptions").tag(AdminPanelTab.subscriptions)
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                Group {
                    switch vm.activeTab {
                    case .dashboard:
                        dashboardList
                    case .subscriptions:
                        subscriptionsList
                    }
                }
            }
            .id(vm.listReloadKey)
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { vm.logout() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.activeTab == .dashboard {
                        Button("Delete ALL Data") { vm.confirmAndDeleteAllData() }
                    } else {
                        Button("Refresh") { vm.reloadSubscriptions() }
                    }
                }
            }
            .onAppear {
                vm.fetchUsers()
                vm.fetchGames()
                if vm.activeTab == .subscriptions {
                    vm.reloadSubscriptions()
                }
            }
            .onChange(of: vm.activeTab) { newTab in
                if newTab == .subscriptions {
                    vm.reloadSubscriptions()
                } else {
                    vm.fetchUsers()
                    vm.fetchGames()
                }
            }
        }
    }

    private var dashboardList: some View {
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
                Text("No users to display").foregroundColor(.gray)
            }

            if !vm.games.isEmpty {
                Section(header: Text("Games")) {
                    ForEach(vm.games, id: \.id) { game in
                        VStack(alignment: .leading) {
                            Text(game.title).font(.headline)
                            if let details = game.details {
                                Text(details)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: vm.deleteGames)
                }
            } else {
                Text("No games to display").foregroundColor(.gray)
            }

            Section {
                if vm.showDump {
                    Button("Hide DB dump") { vm.setShowDump(false) }
                } else {
                    Button("Show ALL DB objects") { vm.setShowDump(true) }
                }
            }

            if vm.showDump {
                Section(header: Text("Inventories")) {
                    if vm.allInventories.isEmpty {
                        Text("No inventories").foregroundColor(.gray)
                    } else {
                        ForEach(vm.allInventories, id: \.id) { inv in
                            VStack(alignment: .leading) {
                                Text(inv.common?.name ?? "[Unnamed]").font(.body)
                                Text("[\(inv.kind.rawValue)] | ID: \(inv.id.stringValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Items")) {
                    if vm.allItems.isEmpty {
                        Text("No items").foregroundColor(.gray)
                    } else {
                        ForEach(vm.allItems, id: \.id) { item in
                            VStack(alignment: .leading) {
                                Text(item.common?.name ?? "[Unnamed Item]").font(.body)
                                Text("Value: \(item.common?.personalValue?.value ?? 0), Weight: \(item.common?.weight?.value ?? 0)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var subscriptionsList: some View {
        List {
            if vm.users.isEmpty {
                Text("No users").foregroundColor(.gray)
            } else {
                ForEach(vm.users, id: \.id) { user in
                    Section {
                        let games = vm.subscriptions[user.id] ?? []
                        if games.isEmpty {
                            Text("No subscriptions").foregroundColor(.secondary)
                        } else {
                            ForEach(games, id: \.id) { g in
                                HStack {
                                    Text(g.isInvalidated ? "[deleted game]" : g.title)
                                    Spacer()
                                    Button("Unsubscribe") {
                                        vm.unsubscribe(userId: user.id, from: g.id)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .onDelete { idxSet in
                                let gs = vm.subscriptions[user.id] ?? []
                                for i in idxSet {
                                    guard i < gs.count else { continue }
                                    vm.unsubscribe(userId: user.id, from: gs[i].id)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(user.username).font(.headline)
                            Spacer()
                            if !(vm.subscriptions[user.id]?.isEmpty ?? true) {
                                Button("Unsub all") {
                                    vm.unsubscribeAll(userId: user.id)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
        }
    }
}

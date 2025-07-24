//
//  InventoryPickerView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 08.07.2025.
//

import SwiftUI
import RealmSwift

struct InventoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: InventoryPickerViewModel

    init(user: User, game: Game, excludedIds: Set<ObjectId>, onSelect: @escaping (Inventory) -> Void) {
        _vm = StateObject(
            wrappedValue: InventoryPickerViewModel(
                user: user,
                game: game,
                excludedIds: excludedIds,
                onSelect: onSelect
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    modePicker

                    switch vm.mode {
                    case .currentGame, .userGames:
                        currentOrUserGamesSection

                    case .global:
                        globalGamesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Select Inventory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $vm.mode) {
            Text("This Game").tag(InventoryPickerMode.currentGame)
            Text("My Games").tag(InventoryPickerMode.userGames)
            Text("All Games").tag(InventoryPickerMode.global)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var currentOrUserGamesSection: some View {
        let grouped = vm.groupedRoots()
        ForEach(grouped, id: \.1?.id) { (_, gameOptional, roots) in
            if let game = gameOptional {
                DisclosureGroup("\(game.title)") {
                    ForEach(roots, id: \.id) { root in
                        InventoryPickerNode(rInventory: root, vm: vm)
                            .padding(.leading, 8)
                    }
                }
            } else {
                DisclosureGroup("Unknown Game") {
                    ForEach(roots, id: \.id) { root in
                        InventoryPickerNode(rInventory: root, vm: vm)
                            .padding(.leading, 8)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var globalGamesSection: some View {
        let grouped = vm.groupedRoots()
        let groupedByUser = Dictionary(grouping: grouped, by: { $0.0 })
        let sortedUsers = groupedByUser.keys.sorted(by: { $0.username < $1.username })

        ForEach(sortedUsers, id: \.id) { user in
            let userGroups = groupedByUser[user] ?? []
            let gameGroups = Dictionary(grouping: userGroups, by: { $0.1 })

            DisclosureGroup("\(user.username)") {
                if gameGroups.keys.count == 1, gameGroups.keys.first == nil {
                    Text("No games")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                } else {
                    let sortedGames = gameGroups.keys.compactMap { $0 }.sorted { $0.title < $1.title }

                    ForEach(sortedGames, id: \.id) { game in
                        let roots = gameGroups[game]?.first?.2 ?? []
                        DisclosureGroup("\(game.title)") {
                            ForEach(roots, id: \.id) { root in
                                InventoryPickerNode(rInventory: root, vm: vm)
                                    .padding(.leading, 8)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
    }
}

private struct InventoryPickerNode: View {
    let rInventory: Inventory
    @ObservedObject var vm: InventoryPickerViewModel
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(vm.children(of: rInventory), id: \.id) { child in
                InventoryPickerNode(rInventory: child, vm: vm)
                    .padding(.leading, 8)
            }
        } label: {
            HStack {
                Image(systemName: "shippingbox")
                Text(rInventory.common?.name ?? "Unnamed")
                Spacer()
                Button {
                    vm.onSelect(rInventory)
                } label: {
                    Image(systemName: "checkmark.circle")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
        }
    }
}

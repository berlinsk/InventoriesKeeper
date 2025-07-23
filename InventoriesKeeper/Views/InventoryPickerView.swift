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
                    Picker("Mode", selection: $vm.mode) {
                        Text("This Game").tag(InventoryPickerMode.currentGame)
                        Text("My Games").tag(InventoryPickerMode.userGames)
                        Text("All Games").tag(InventoryPickerMode.global)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch vm.mode {
                    case .currentGame, .userGames:
                        ForEach(vm.groupedRoots(), id: \.1.id) { (_, game, roots) in
                            DisclosureGroup("\(game.title)") {
                                ForEach(roots, id: \.id) { root in
                                    InventoryPickerNode(rInventory: root, vm: vm)
                                        .padding(.leading, 8)
                                }
                            }
                        }

                    case .global:
                        ForEach(Dictionary(grouping: vm.groupedRoots(), by: { $0.0 }).keys.sorted(by: { $0.username < $1.username }), id: \.id) { user in
                            DisclosureGroup("\(user.username)") {
                                ForEach(vm.groupedRoots().filter { $0.0.id == user.id }, id: \.1.id) { (_, game, roots) in
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

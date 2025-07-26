//
//  RootInventoryShareView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 26.07.2025.
//

import SwiftUI
import RealmSwift

struct RootInventoryShareView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: RootInventoryShareViewModel

    init(game: Game) {
        _vm = StateObject(wrappedValue: RootInventoryShareViewModel(game: game))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Select root inventories to share:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                List(vm.rootInventories, id: \.id) { inv in
                    Button {
                        vm.toggleRootSelection(inv.id)
                    } label: {
                        HStack {
                            Image(systemName: vm.selectedRootIds.contains(inv.id) ? "checkmark.square.fill" : "square")
                            Text(inv.common?.name ?? "Unnamed")
                            Spacer()
                            Text("[\(inv.kind.rawValue)]")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Divider()

                Text("Select users to share with:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                List(vm.users, id: \.id) { user in
                    Button {
                        vm.toggleUserSelection(user.id)
                    } label: {
                        HStack {
                            Image(systemName: vm.selectedUserIds.contains(user.id) ? "checkmark.circle.fill" : "circle")
                            Text(user.username)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Divider()

                Button("Share Selected") {
                    vm.shareSelectedRoots()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.selectedRootIds.isEmpty || vm.selectedUserIds.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Share Root Inventories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

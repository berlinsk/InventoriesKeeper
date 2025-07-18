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
    @ObservedResults(RInventory.self) private var allInventories

    init(excludedIds: Set<ObjectId>,
         onSelect: @escaping (Inventory) -> Void) {

        _vm = StateObject(
            wrappedValue: InventoryPickerViewModel(
                excludedIds: excludedIds,
                onSelect: onSelect
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(vm.roots(from: allInventories), id: \.id) { root in
                        InventoryPickerNode(rInventory : root, vm: vm)
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
    let rInventory: RInventory
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
                    vm.onSelect(Inventory(model: rInventory))
                } label: {
                    Image(systemName: "checkmark.circle")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
        }
    }
}

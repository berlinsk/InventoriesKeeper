//
//  InventoryPickerView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 08.07.2025.
//

import SwiftUI
import RealmSwift

struct InventoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (Inventory) -> Void
    
    @ObservedResults(RInventory.self) var allInventories
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(allInventories.filter { $0.common?.ownerId == $0.id }, id: \.id) { rootInv in
                        InventoryPickerNode(rInventory: rootInv, onSelect: onSelect)
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

struct InventoryPickerNode: View {
    let rInventory: RInventory
    let onSelect: (Inventory) -> Void
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $expanded,
            content: {
                ForEach(rInventory.inventories, id: \.id) { child in
                    InventoryPickerNode(rInventory: child, onSelect: onSelect)
                        .padding(.leading, 8)
                }
            },
            label: {
                HStack {
                    Image(systemName: "shippingbox")
                    Text(rInventory.common?.name ?? "Unnamed")
                    Spacer()
                    Button {
                        onSelect(Inventory(model: rInventory))
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.vertical, 4)
            }
        )
    }
}

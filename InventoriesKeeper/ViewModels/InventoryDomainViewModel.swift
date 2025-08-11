//
//  InventoryDomainViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 19.07.2025.
//

import Foundation
import SwiftUI
import RealmSwift

final class InventoryDomainViewModel: ObservableObject {
    @Published var errorText: AlertText?
    @Published var selection: Set<ObjectId> = []
    @Published var showPicker = false

    func addItem(kind: ItemKind, name: String, to inventory: Inventory) {
        let realm = try! Realm()
        let item = SeedFactory.makeItem(kind: kind, name: name, ownerInventoryID: inventory.id)
        DispatchQueue.main.async {
            do {
                try TransferService.shared.add(item: item, to: inventory, in: realm)
            } catch {
                self.errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    func addInventory(kind: InventoryKind, name: String, to inventory: Inventory) {
        let inv = Inventory.createChild(kind: kind, name: name, ownerInventoryID: inventory.id)
        let realm = try! Realm()
        DispatchQueue.main.async {
            do {
                try TransferService.shared.add(inventory: inv, to: inventory, in: realm)
            } catch {
                self.errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    func moveSelected(selection: Set<ObjectId>, from inventory: Inventory, to destination: Inventory) {
        DispatchQueue.main.async {
            do {
                let destId = destination.id
                for id in selection {
                    if inventory.items.contains(where: { $0.id == id }) {
                        try TransferService.shared.moveItem(withId: id, to: destId)
                    } else if inventory.inventories.contains(where: { $0.id == id }) {
                        try TransferService.shared.moveInventory(withId: id, to: destId)
                    }
                }
            } catch {
                self.errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    func computeExcludedIds(selection: Set<ObjectId>, from inventory: Inventory) -> Set<ObjectId> {
        var excluded: Set<ObjectId> = []
        for id in selection {
            if let rInv = inventory.inventories.first(where: { $0.id == id }) {
                excluded.insert(rInv.id)
                collectChildIds(of: rInv, into: &excluded)
            }
        }
        return excluded
    }

    private func collectChildIds(of inventory: Inventory, into set: inout Set<ObjectId>) {
        for child in inventory.inventories {
            set.insert(child.id)
            collectChildIds(of: child, into: &set)
        }
    }

    func delete(at indexSet: IndexSet, isItem: Bool, from inventory: Inventory) {
        for idx in indexSet {
            let realm = try! Realm()
            do {
                if isItem {
                    let rItem = inventory.items[idx]
                    try TransferService.shared.remove(item: rItem, from: inventory, in: realm)
                } else {
                    let rInv = inventory.inventories[idx]
                    try TransferService.shared.remove(inventory: rInv, from: inventory, in: realm)
                }
            } catch {
                self.errorText = AlertText(text: error.localizedDescription)
            }
        }
    }
}

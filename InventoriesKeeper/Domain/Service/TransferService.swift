//
//  TransferService.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

enum TransferError: Error {
    case capacityExceeded
    case cyclicMove
    case notFound
}

final class TransferService {
    static let shared = TransferService()
    private init() {}

    private func write(_ block: () throws -> Void) throws {
        let realm = try Realm()
        if realm.isInWriteTransaction {
            try block()
        } else {
            try realm.write { try block() }
        }
    }

    func add(object: GameObject, to inventory: Inventory) throws {
        guard let live = inventory.model.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try write {
            if let item = object as? Item {
                if !inventory.canAccept(object: item) { throw TransferError.capacityExceeded }
                live.items.append(item.model)
            } else if let inv = object as? Inventory {
                if isCycle(source: inv.model, target: live) { throw TransferError.cyclicMove }
                if !inventory.canAccept(object: inv) { throw TransferError.capacityExceeded }
                live.inventories.append(inv.model)
            }
        }
    }

    func remove(object: GameObject, from inventory: Inventory) throws {
        guard let live = inventory.model.thaw(),
              let realm = live.realm else {
            fatalError("inventory model is not managed by realm")
        }

        try realm.write {
            if let item = object as? Item {
                if let idx = live.items.firstIndex(where: { $0.id == item.model.id }) {
                    let toDelete = live.items[idx]
                    live.items.remove(at: idx)
                    realm.delete(toDelete)
                } else {
                    throw TransferError.notFound
                }
            } else if let inv = object as? Inventory {
                if let idx = live.inventories.firstIndex(where: { $0.id == inv.model.id }) {
                    let toDelete = live.inventories[idx]
                    live.inventories.remove(at: idx)
                    deleteInventoryRecursively(toDelete, in: realm)
                } else {
                    throw TransferError.notFound
                }
            }
        }
    }
    
    func deleteInventoryRecursively(_ inventory: RInventory, in realm: Realm) {
        for childInv in inventory.inventories {
            deleteInventoryRecursively(childInv, in: realm)
        }
        realm.delete(inventory.items)
        realm.delete(inventory)
    }

    private func isCycle(source: RInventory, target: RInventory) -> Bool {
        if source.id == target.id { return true }
        for child in target.inventories where isCycle(source: source, target: child) {
            return true
        }
        return false
    }
}

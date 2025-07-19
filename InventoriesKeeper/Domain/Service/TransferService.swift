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

    private func write(in realm: Realm, _ block: () throws -> Void) throws {
        if realm.isInWriteTransaction {
            try block()
        } else {
            try realm.write { try block() }
        }
    }

    func add(item: Item, to inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try write(in: realm) {
            if !live.canAccept(rItem: item) {
                throw TransferError.capacityExceeded
            }
            live.items.append(item)
            live.updateCachedValuesRecursively()
        }
    }

    func add(inventory child: Inventory, to inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try write(in: realm) {
            if isCycle(source: child, target: live) {
                throw TransferError.cyclicMove
            }
            if !live.canAccept(rInventory: child) {
                throw TransferError.capacityExceeded
            }
            live.inventories.append(child)
            live.updateCachedValuesRecursively()
        }
    }

    func remove(item: Item, from inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try realm.write {
            if let idx = live.items.firstIndex(where: { $0.id == item.id }) {
                let toDelete = live.items[idx]
                live.items.remove(at: idx)
                realm.delete(toDelete)
                live.updateCachedValuesRecursively()
            } else {
                throw TransferError.notFound
            }
        }
    }

    func remove(inventory child: Inventory, from inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try realm.write {
            if let idx = live.inventories.firstIndex(where: { $0.id == child.id }) {
                let toDelete = live.inventories[idx]
                live.inventories.remove(at: idx)
                deleteInventoryRecursively(toDelete, in: realm)
                live.updateCachedValuesRecursively()
            } else {
                throw TransferError.notFound
            }
        }
    }

    
    func deleteInventoryRecursively(_ inventory: Inventory, in realm: Realm) {
        for childInv in inventory.inventories {
            deleteInventoryRecursively(childInv, in: realm)
        }
        realm.delete(inventory.items)
        realm.delete(inventory)
    }
    
    func moveItem(withId itemId: ObjectId, to targetInventoryId: ObjectId) throws {
        let realm = try Realm()
        try realm.write {
            guard let item    = realm.object(ofType: Item.self, forPrimaryKey: itemId),
                  let target  = realm.object(ofType: Inventory.self, forPrimaryKey: targetInventoryId),
                  let parent  = realm.objects(Inventory.self)
                                    .first(where: { $0.items.contains(item) })
            else {
                throw TransferError.notFound
            }

            if !target.canAccept(rItem: item) {
                throw TransferError.capacityExceeded
            }

            if let idx = parent.items.firstIndex(of: item) {
                parent.items.remove(at: idx)
            }
            target.items.append(item)

            target.updateCachedValuesRecursively()
            parent.updateCachedValuesRecursively()
        }
    }

    func moveInventory(withId childId: ObjectId, to targetInventoryId: ObjectId) throws {
        let realm = try Realm()
        try realm.write {
            guard let child   = realm.object(ofType: Inventory.self, forPrimaryKey: childId),
                  let target  = realm.object(ofType: Inventory.self, forPrimaryKey: targetInventoryId),
                  let parent  = realm.objects(Inventory.self)
                                    .first(where: { $0.inventories.contains(child) })
            else {
                throw TransferError.notFound
            }

            if child.id == target.id || child.isAncestor(of: target) {
                throw TransferError.cyclicMove
            }

            if let max = target.maxCarryWeight {
                let childWeight = child.totalWeight
                let newTotal = target.totalWeight + childWeight
                if newTotal.inBaseUnit > max.inBaseUnit {
                    throw TransferError.capacityExceeded
                }
            }

            if let idx = parent.inventories.firstIndex(of: child) {
                parent.inventories.remove(at: idx)
            }
            target.inventories.append(child)

            target.updateCachedValuesRecursively()
            parent.updateCachedValuesRecursively()
        }
    }

    private func isCycle(source: Inventory, target: Inventory) -> Bool {
        if source.id == target.id { return true }
        for child in target.inventories where isCycle(source: source, target: child) {
            return true
        }
        return false
    }
}

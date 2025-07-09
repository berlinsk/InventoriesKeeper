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

    func add(object: GameObject, to inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.model.thaw() else {
            fatalError("inventory model is no longer in realm")
        }
        try write(in: realm) {
            if let item = object as? Item {
                if !inventory.canAccept(object: item) { throw TransferError.capacityExceeded }
                live.items.append(item.model)
            } else if let inv = object as? Inventory {
                if isCycle(source: inv.model, target: live) { throw TransferError.cyclicMove }
                if !inventory.canAccept(object: inv) { throw TransferError.capacityExceeded }
                live.inventories.append(inv.model)
            }
            live.updateCachedValuesRecursively()
        }
    }

    func remove(object: GameObject, from inventory: Inventory, in realm: Realm) throws {
        guard let live = inventory.model.thaw() else {
            fatalError("inventory model is no longer in realm")
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
            live.updateCachedValuesRecursively()
        }
    }
    
    func deleteInventoryRecursively(_ inventory: RInventory, in realm: Realm) {
        for childInv in inventory.inventories {
            deleteInventoryRecursively(childInv, in: realm)
        }
        realm.delete(inventory.items)
        realm.delete(inventory)
    }
    
    func moveItem(withId itemId: ObjectId, to targetInventoryId: ObjectId) throws {
        let realm = try Realm()
        try realm.write {
            guard let item    = realm.object(ofType: RItem.self, forPrimaryKey: itemId),
                  let target  = realm.object(ofType: RInventory.self, forPrimaryKey: targetInventoryId),
                  let parent  = realm.objects(RInventory.self)
                                    .first(where: { $0.items.contains(item) })
            else {
                throw TransferError.notFound
            }

            let wrapperTarget = Inventory(model: target)
            let wrapperItem   = Item(model: item)
            if !wrapperTarget.canAccept(object: wrapperItem) {
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
            guard let child   = realm.object(ofType: RInventory.self, forPrimaryKey: childId),
                  let target  = realm.object(ofType: RInventory.self, forPrimaryKey: targetInventoryId),
                  let parent  = realm.objects(RInventory.self)
                                    .first(where: { $0.inventories.contains(child) })
            else {
                throw TransferError.notFound
            }

            if child.id == target.id || child.isAncestor(of: target) {
                throw TransferError.cyclicMove
            }

            let wrapperTarget = Inventory(model: target)
            let wrapperChild  = Inventory(model: child)
            if !wrapperTarget.canAccept(object: wrapperChild) {
                throw TransferError.capacityExceeded
            }

            if let idx = parent.inventories.firstIndex(of: child) {
                parent.inventories.remove(at: idx)
            }
            target.inventories.append(child)

            target.updateCachedValuesRecursively()
            parent.updateCachedValuesRecursively()
        }
    }

    private func isCycle(source: RInventory, target: RInventory) -> Bool {
        if source.id == target.id { return true }
        for child in target.inventories where isCycle(source: source, target: child) {
            return true
        }
        return false
    }
}

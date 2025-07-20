//
//  SeedFactory.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 20.07.2025.
//

import SwiftUI
import RealmSwift

enum SeedFactory {
    static func makeInventory(kind: InventoryKind, name: String, ownerId: ObjectId? = nil) -> Inventory {
        let inv = Inventory()
        inv.id = ObjectId.generate()
        let common = ItemInventoryCommonFields()
        common.name = name
        common.ownerId = ownerId ?? inv.id
        common.weight = Weight(value: Double.random(in: 5...20), unit: .kg)
        common.createdAt = Date()
        inv.common = common
        inv.kind = kind
        return inv
    }

    static func addRootInventory() -> Inventory {
        let realm = try! Realm()
        let inv = makeInventory(kind: .generic, name: "Root \(Int.random(in: 1...999))")
        try! realm.write {
            realm.add(inv)
        }
        return inv
    }


    static func makeItem(kind: ItemKind, name: String, ownerId: ObjectId) -> Item {
        let item = Item()
        item.id = ObjectId.generate()
        let common = ItemInventoryCommonFields()
        common.name      = name
        common.ownerId   = ownerId
        common.weight    = Weight(value: Double.random(in: 0.1...3000), unit: .kg)
        common.createdAt = Date()
        item.common = common
        item.kind   = kind
        return item
    }
}

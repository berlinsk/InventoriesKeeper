//
//  Inventory.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

final class Inventory: InventoryProtocol {
    let model: RInventory

    init(model: RInventory) { self.model = model }

    var id: ObjectId { model.id }

    var ownerId: ObjectId {
        get { model.common?.ownerId ?? ObjectId.generate() }
        set { model.common?.ownerId = newValue }
    }

    var name: String {
        get { model.common?.name ?? "" }
        set { model.common?.name = newValue }
    }

    var weight: Weight? {
        get { model.common?.weight }
        set { model.common?.weight = newValue }
    }

    var personalValue: Currency? {
        get { model.common?.personalValue }
        set { model.common?.personalValue = newValue }
    }

    var moneyAmount: Currency? {
        get { model.common?.moneyAmount }
        set { model.common?.moneyAmount = newValue }
    }

    var descriptionText: String? {
        get { model.common?.descriptionText }
        set { model.common?.descriptionText = newValue }
    }

    var createdAt: Date {
        get { model.common?.createdAt ?? Date() }
        set { model.common?.createdAt = newValue }
    }

    var photos: [String] {
        get { Array(model.common?.photos ?? List<String>()) }
        set {
            let list = List<String>()
            list.append(objectsIn: newValue)
            model.common?.photos = list
        }
    }

    var kind: InventoryKind {
        get { model.kind }
        set { model.kind = newValue }
    }

    var maxCarryWeight: Weight? {
        get { model.maxCarryWeight }
        set { model.maxCarryWeight = newValue }
    }

    var characterDetails: CharacterInventoryDetails? {
        get { model.characterDetails }
        set { model.characterDetails = newValue }
    }

    var locationDetails: LocationInventoryDetails? {
        get { model.locationDetails }
        set { model.locationDetails = newValue }
    }

    var vehicleDetails: VehicleInventoryDetails? {
        get { model.vehicleDetails }
        set { model.vehicleDetails = newValue }
    }

    var items: List<RItem> { model.items }
    var inventories: List<RInventory> { model.inventories }

    var totalWeight: Weight {
        Weight(value: model.cachedTotalWeight, unit: .kg)
    }

    var totalPersonalValue: Currency {
        Currency(value: model.cachedTotalPersonalValue, unit: .currency1)
    }

    var totalMoneyAmount: Currency {
        Currency(value: model.cachedTotalMoneyAmount, unit: .currency1)
    }

    var totalValue: Currency {
        Currency(value: model.cachedTotalValue, unit: .currency1)
    }

    func add(object: GameObject) throws {
        try TransferService.shared.add(object: object, to: self)
    }

    func remove(object: GameObject) throws {
        try TransferService.shared.remove(object: object, from: self)
    }
    
    func deleteRecursively() throws {
        guard let realm = model.realm else { return }
        try realm.write {
            TransferService.shared.deleteInventoryRecursively(model, in: realm)
        }
    }

    func canAccept(object: GameObject) -> Bool {
        guard let objWeight = object.weight else { return true }
        guard let max = maxCarryWeight else { return true }
        let newTotal = totalWeight + objWeight
        return newTotal.inBaseUnit <= max.inBaseUnit
    }
}

extension Inventory {
    static func createRoot(kind: InventoryKind, name: String) -> Inventory {
        let realm = try! Realm()
        var newInv: RInventory!
        try! realm.write {
            newInv = SeedFactory.makeInventory(kind: kind, name: name)
            realm.add(newInv)
            newInv.updateCachedValuesRecursively()
        }
        return Inventory(model: newInv)
    }
    
    static func createChild(kind: InventoryKind, name: String, ownerId: ObjectId) -> Inventory {
        let realm = try! Realm()
        var newInv: RInventory!
        try! realm.write {
            newInv = SeedFactory.makeInventory(kind: kind, name: name, ownerId: ownerId)
            realm.add(newInv)
            newInv.updateCachedValuesRecursively()
        }
        return Inventory(model: newInv)
    }
    
    static func findOrCreateRoot(kind: InventoryKind, name: String) -> Inventory {
        let realm = try! Realm()
        if let existing = realm.objects(RInventory.self).filter("kind == %@", kind.rawValue).first {
            return Inventory(model: existing)
        } else {
            return Inventory.createRoot(kind: kind, name: name)
        }
    }
    
    static func getAllRoots() -> [Inventory] {
        let realm = try! Realm()
        return realm.objects(RInventory.self)
            .filter("common.ownerId == id")
            .map { Inventory(model: $0) }
    }

    static func findRoot(kind: InventoryKind) -> Inventory? {
        let realm = try! Realm()
        if let existing = realm.objects(RInventory.self)
            .filter("kind == %@ AND common.ownerId == id", kind.rawValue)
            .first {
            return Inventory(model: existing)
        }
        return nil
    }
}

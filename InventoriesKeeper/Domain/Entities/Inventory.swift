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

    var totalWeight: Weight { model.totalWeight }
    var totalPersonalValue: Currency { model.totalPersonalValue }
    var totalMoneyAmount: Currency { model.totalMoneyAmount }
    var totalValue: Currency { model.totalValue }

    func add(object: GameObject) throws {}

    func remove(object: GameObject) throws {}

    func canAccept(object: GameObject) -> Bool {
        guard let objWeight = object.weight else { return true }
        guard let max = maxCarryWeight else { return true }
        let newTotal = model.totalWeight + objWeight
        return newTotal.inBaseUnit <= max.inBaseUnit
    }
}

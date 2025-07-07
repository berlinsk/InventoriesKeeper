//
//  RInventory.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation
import RealmSwift

enum InventoryKind: String, PersistableEnum {
    case character
    case location
    case vehicle
    case generic
}

class CharacterInventoryDetails: EmbeddedObject {
    @Persisted var strength: Double?
    @Persisted var skill: Double?
    @Persisted var intelligence: Double?
    @Persisted var birthDate: GameDate?
    @Persisted var deathDate: GameDate?
}

class LocationInventoryDetails: EmbeddedObject {
    @Persisted var isExplored: Bool?
}

class VehicleInventoryDetails: EmbeddedObject {
    @Persisted var mileage: Double?
    @Persisted var tankVolume: Volume?
    @Persisted var currentFuelLevel: Volume?
    @Persisted var fuelConsumptionPer100km: Volume?
    @Persisted var horsepower: Double?
    @Persisted var torque: Double?
    @Persisted var engineVolume: Volume?
    @Persisted var maxSpeed: Double?
    @Persisted var accelerationTo100: Double?
    @Persisted var transmissionType: String?
    @Persisted var driveType: String?
    @Persisted var releaseDate: GameDate?
    @Persisted var defectList: String?
}

class RInventory: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var common: ItemInventoryCommonFields?
    @Persisted var maxCarryWeight: Weight?
    @Persisted var kind: InventoryKind
    @Persisted var characterDetails: CharacterInventoryDetails?
    @Persisted var locationDetails: LocationInventoryDetails?
    @Persisted var vehicleDetails: VehicleInventoryDetails?
    @Persisted var items = List<RItem>()
    @Persisted var inventories = List<RInventory>()
    @Persisted var cachedTotalWeight: Double
    @Persisted var cachedTotalPersonalValue: Double
    @Persisted var cachedTotalMoneyAmount: Double
    @Persisted var cachedTotalValue: Double
    var totalWeight: Weight {
        let childItemsWeight = items.reduce(Weight(value: 0, unit: WeightUnit.kg)) { sum, item in
            if let weight = item.common?.weight {
                return sum + weight
            }
            return sum
        }
        let childInventoriesWeight = inventories.reduce(Weight(value: 0, unit: WeightUnit.kg)) { $0 + $1.totalWeight }
        return (common?.weight ?? Weight(value: 0, unit: WeightUnit.kg)) + childItemsWeight + childInventoriesWeight
    }

    var totalPersonalValue: Currency {
        let childItemsValue = items.reduce(Currency(value: 0, unit: CurrencyUnit.currency1)) { sum, item in
            if let value = item.common?.personalValue {
                return sum + value
            }
            return sum
        }
        let childInventoriesValue = inventories.reduce(Currency(value: 0, unit: CurrencyUnit.currency1)) { $0 + $1.totalPersonalValue }
        return (common?.personalValue ?? Currency(value: 0, unit: CurrencyUnit.currency1)) + childItemsValue + childInventoriesValue
    }

    var totalMoneyAmount: Currency {
        let childItemsMoney = items.reduce(Currency(value: 0, unit: CurrencyUnit.currency1)) { sum, item in
            if let value = item.common?.moneyAmount {
                return sum + value
            }
            return sum
        }
        let childInventoriesMoney = inventories.reduce(Currency(value: 0, unit: CurrencyUnit.currency1)) { $0 + $1.totalMoneyAmount }
        return (common?.moneyAmount ?? Currency(value: 0, unit: CurrencyUnit.currency1)) + childItemsMoney + childInventoriesMoney
    }

    var totalValue: Currency {
        totalPersonalValue + totalMoneyAmount
    }

}

extension RInventory {
    func updateCachedValuesRecursively() {
        guard let realm = self.realm else { return }
        
        let itemWeight = items.reduce(0.0) { $0 + ($1.common?.weight?.value ?? 0) }
        let childWeight = inventories.reduce(0.0) { $0 + $1.cachedTotalWeight }
        let selfWeight = common?.weight?.value ?? 0
        cachedTotalWeight = selfWeight + itemWeight + childWeight

        let itemValue = items.reduce(0.0) { $0 + ($1.common?.personalValue?.value ?? 0) }
        let childValue = inventories.reduce(0.0) { $0 + $1.cachedTotalPersonalValue }
        let selfValue = common?.personalValue?.value ?? 0
        cachedTotalPersonalValue = selfValue + itemValue + childValue

        let itemMoney = items.reduce(0.0) { $0 + ($1.common?.moneyAmount?.value ?? 0) }
        let childMoney = inventories.reduce(0.0) { $0 + $1.cachedTotalMoneyAmount }
        let selfMoney = common?.moneyAmount?.value ?? 0
        cachedTotalMoneyAmount = selfMoney + itemMoney + childMoney

        cachedTotalValue = cachedTotalPersonalValue + cachedTotalMoneyAmount

        if let ownerId = common?.ownerId,
           let parent = realm.object(ofType: RInventory.self, forPrimaryKey: ownerId),
           parent.id != self.id {
            parent.updateCachedValuesRecursively()
        }
    }
}

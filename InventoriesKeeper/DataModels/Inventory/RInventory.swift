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
    @Persisted var birthDate: Date?
    @Persisted var deathDate: Date?
}

class LocationInventoryDetails: EmbeddedObject {
    @Persisted var isExplored: Bool?
}

class VehicleInventoryDetails: EmbeddedObject {
    @Persisted var mileage: Double?
    @Persisted var tankVolume: Double?
    @Persisted var currentFuelLevel: Double?
    @Persisted var fuelConsumptionPer100km: Double?
    @Persisted var horsepower: Double?
    @Persisted var torque: Double?
    @Persisted var engineVolume: Double?
    @Persisted var maxSpeed: Double?
    @Persisted var accelerationTo100: Double?
    @Persisted var transmissionType: String?
    @Persisted var driveType: String?
    @Persisted var releaseDate: Date?
    @Persisted var defectList: String?
}

class RInventory: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var common: ItemInventoryCommonFields?
    @Persisted var maxCarryWeight: Double?
    @Persisted var kind: InventoryKind
    @Persisted var characterDetails: CharacterInventoryDetails?
    @Persisted var locationDetails: LocationInventoryDetails?
    @Persisted var vehicleDetails: VehicleInventoryDetails?
    @Persisted var items = List<RItem>()
    @Persisted var inventories = List<RInventory>()
    var totalWeight: Double {
        let childItemsWeight = items.reduce(into: 0) { sum, item in
            if let common = item.common {
                sum += common.weight
            }
        }
        let childInventoriesWeight = inventories.reduce(into: 0) { $0 += $1.totalWeight }
        return (common?.weight ?? 0) + childItemsWeight + childInventoriesWeight
    }

    var totalPersonalValue: Double {
        let childItemsValue = items.reduce(into: 0) { sum, item in
            if let common = item.common {
                sum += common.personalValue ?? 0
            }
        }
        let childInventoriesValue = inventories.reduce(into: 0) { $0 += $1.totalPersonalValue }
        return (common?.personalValue ?? 0) + childItemsValue + childInventoriesValue
    }

    var totalMoneyAmount: Double {
        let childItemsMoney = items.reduce(into: 0) { sum, item in
            if let common = item.common {
                sum += common.moneyAmount ?? 0
            }
        }
        let childInventoriesMoney = inventories.reduce(into: 0) { $0 += $1.totalMoneyAmount }
        return (common?.moneyAmount ?? 0) + childItemsMoney + childInventoriesMoney
    }

    var totalValue: Double {
        totalPersonalValue + totalMoneyAmount
    }
}

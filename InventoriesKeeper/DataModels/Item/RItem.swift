//
//  RItem.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation
import RealmSwift

enum ItemKind: String, PersistableEnum {
    case food
    case liquid
    case weapon
    case book
    case generic
}

class FoodItemDetails: EmbeddedObject {
    @Persisted var calories: Calorie?
}

class LiquidItemDetails: EmbeddedObject {
    @Persisted var calories: Calorie?
    @Persisted var volume: Volume?
}

class BookItemDetails: EmbeddedObject {
    @Persisted var content: List<String>
}

class WeaponItemDetails: EmbeddedObject {
    @Persisted var accuracy: Double?
}

class RItem: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var common: ItemInventoryCommonFields?
    @Persisted var expirationDate: GameDate?
    @Persisted var kind: ItemKind
    @Persisted var foodDetails: FoodItemDetails?
    @Persisted var liquidDetails: LiquidItemDetails?
    @Persisted var weaponDetails: WeaponItemDetails?
    @Persisted var bookDetails: BookItemDetails?
}


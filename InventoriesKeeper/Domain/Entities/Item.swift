//
//  Item.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

final class Item: ItemProtocol {
    let model: RItem

    init(model: RItem) { self.model = model }
    
    init(kind: ItemKind, name: String, ownerId: ObjectId) {
        let rItem = SeedFactory.makeItem(kind: kind, name: name, ownerId: ownerId)
        self.model = rItem
    }

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

    var expirationDate: GameDate? {
        get { model.expirationDate }
        set { model.expirationDate = newValue }
    }

    var kind: ItemKind {
        get { model.kind }
        set { model.kind = newValue }
    }

    var foodDetails: FoodItemDetails? {
        get { model.foodDetails }
        set { model.foodDetails = newValue }
    }

    var liquidDetails: LiquidItemDetails? {
        get { model.liquidDetails }
        set { model.liquidDetails = newValue }
    }

    var weaponDetails: WeaponItemDetails? {
        get { model.weaponDetails }
        set { model.weaponDetails = newValue }
    }

    var bookDetails: BookItemDetails? {
        get { model.bookDetails }
        set { model.bookDetails = newValue }
    }
}

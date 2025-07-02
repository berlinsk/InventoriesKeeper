//
//  ItemInventoryCommonFields.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation
import RealmSwift

class ItemInventoryCommonFields: EmbeddedObject {
    @Persisted var name: String
    @Persisted var ownerId: ObjectId
    @Persisted var weight: Double
    @Persisted var personalValue: Double?
    @Persisted var moneyAmount: Double?
    @Persisted var descriptionText: String?
    @Persisted var createdAt: Date
    @Persisted var photos: List<String>
}

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
    @Persisted var ownerInventoryID: ObjectId
    @Persisted var ownerUserID: ObjectId?
    @Persisted var weight: Weight?
    @Persisted var personalValue: Currency?
    @Persisted var moneyAmount: Currency?
    @Persisted var descriptionText: String?
    @Persisted var createdAt: Date
    @Persisted var photos: List<String>
}

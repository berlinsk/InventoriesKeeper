//
//  Game.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import Foundation
import RealmSwift

class Game: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var ownerId: ObjectId?
    @Persisted var title: String = ""
    @Persisted var details: String?
    @Persisted var isPublic: Bool = false

    @Persisted var rootInventories = List<Inventory>()
}

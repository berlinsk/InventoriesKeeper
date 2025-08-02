//
//  Game.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import Foundation
import RealmSwift

class SharedRootInventory: EmbeddedObject {
    @Persisted var user: User?
    @Persisted var inventory: Inventory?
}

class Game: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var ownerId: ObjectId?
    @Persisted var title: String = ""
    @Persisted var details: String?
    @Persisted var isPublic: Bool = false

    @Persisted var participantIds = List<ObjectId>()
    
    @Persisted var publicRootInventories = List<SharedRootInventory>()
    @Persisted var privateRootInventories = List<Inventory>()
}

//
//  Game.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import Foundation
import RealmSwift

class SharedRootAccess: EmbeddedObject {
    @Persisted var userId: ObjectId
    @Persisted var inventoryId: ObjectId
}

class Game: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var ownerId: ObjectId?
    @Persisted var title: String = ""
    @Persisted var details: String?
    @Persisted var isPublic: Bool = false

    @Persisted var participantIds = List<ObjectId>()
    @Persisted var sharedRootAccess = List<SharedRootAccess>()
    
    @Persisted var publicRootInventories = List<Inventory>()
    @Persisted var privateRootInventories = List<Inventory>()
}

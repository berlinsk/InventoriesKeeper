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

enum RootInventoryType {
    case global
    case mainCharacter

    var name: String {
        switch self {
        case .global: return "Global Inventory"
        case .mainCharacter: return "Main Character"
        }
    }

    var kind: InventoryKind {
        switch self {
        case .global: return .location
        case .mainCharacter: return .character
        }
    }

    var isPublic: Bool {
        switch self {
        case .global: return true
        case .mainCharacter: return false
        }
    }
}

class Game: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var gameOwnerUserID: ObjectId?
    @Persisted var title: String = ""
    @Persisted var details: String?
    @Persisted var isPublic: Bool = false

    @Persisted var participantIds = List<ObjectId>()
    
    @Persisted var globalInventory: Inventory?
    @Persisted var mainCharacterInventories = List<Inventory>()
    @Persisted var publicRootInventories = List<SharedRootInventory>()
    @Persisted var privateRootInventories = List<Inventory>()
}

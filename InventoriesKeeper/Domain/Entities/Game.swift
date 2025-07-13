//
//  Game.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import Foundation
import RealmSwift

struct Game: Hashable {
    let model: RGame

    var id: ObjectId { model.id }
    
    var ownerId: ObjectId? {
        get { model.ownerId }
        set { model.ownerId = newValue }
    }
    
    var title: String {
        get { model.title }
        set { model.title = newValue }
    }
    var details: String? {
        get { model.details }
        set { model.details = newValue }
    }
    var isPublic: Bool {
        get { model.isPublic }
        set { model.isPublic = newValue }
    }

    var rootInventories: List<RInventory> { model.rootInventories }
}

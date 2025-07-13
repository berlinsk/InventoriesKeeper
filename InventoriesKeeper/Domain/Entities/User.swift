//
//  User.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 12.07.2025.
//

import Foundation
import RealmSwift

struct User: Hashable {
    let model: RUser

    var id: ObjectId { model.id }

    var username: String {
        get { model.username }
        set { model.username = newValue }
    }

    var password: String {
        get { model.password }
        set { model.password = newValue }
    }

    var isAdmin: Bool {
        get { model.isAdmin }
        set { model.isAdmin = newValue }
    }

    var isLoggedIn: Bool {
        get { model.isLoggedIn }
        set { model.isLoggedIn = newValue }
    }

    var games: [Game] {
        get { model.games.map(Game.init) }
    }
}

//
//  RUser.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 10.07.2025.
//

import Foundation
import RealmSwift

class RUser: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var username: String
    @Persisted var password: String
    @Persisted var isAdmin: Bool

    @Persisted var games = List<RGame>()
}

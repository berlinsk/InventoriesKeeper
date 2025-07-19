//
//  Calorie.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

class Calorie: EmbeddedObject {
    @Persisted var value: Double
}

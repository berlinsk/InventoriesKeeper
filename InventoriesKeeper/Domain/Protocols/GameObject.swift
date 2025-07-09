//
//  GameObject.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

protocol GameObject {
    var id: ObjectId { get }
    var ownerId: ObjectId { get set }
    var name: String { get set }
    var weight: Weight? { get }
}

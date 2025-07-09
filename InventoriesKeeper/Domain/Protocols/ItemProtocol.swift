//
//  ItemProtocol.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

protocol ItemProtocol: GameObject {
    var model: RItem { get }
    var expirationDate: GameDate? { get set }
    var kind: ItemKind { get set }

    var foodDetails: FoodItemDetails? { get set }
    var liquidDetails: LiquidItemDetails? { get set }
    var weaponDetails: WeaponItemDetails? { get set }
    var bookDetails: BookItemDetails? { get set }

    func use(by inventory: Inventory) throws
}

extension ItemProtocol {
    func use(by inventory: Inventory) throws { }
}

//
//  InventoryProtocol.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import Foundation
import RealmSwift

protocol InventoryProtocol: GameObject {
    var model: RInventory { get }
    var kind: InventoryKind { get set }
    var maxCarryWeight: Weight? { get set }

    var characterDetails: CharacterInventoryDetails? { get set }
    var locationDetails: LocationInventoryDetails? { get set }
    var vehicleDetails: VehicleInventoryDetails? { get set }

    var items: List<RItem> { get }
    var inventories: List<RInventory> { get }

    var totalWeight: Weight { get }
    var totalPersonalValue: Currency { get }
    var totalMoneyAmount: Currency { get }
    var totalValue: Currency { get }

    func add(object: GameObject) throws
    func remove(object: GameObject) throws
    func canAccept(object: GameObject) -> Bool
}

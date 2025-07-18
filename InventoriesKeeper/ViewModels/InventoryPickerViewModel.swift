//
//  InventoryPickerViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 15.07.2025.
//

import Foundation
import RealmSwift

final class InventoryPickerViewModel: ObservableObject {
    @Published var excludedIds: Set<ObjectId>

    let onSelect: (Inventory) -> Void

    init(excludedIds: Set<ObjectId>, onSelect: @escaping (Inventory) -> Void) {
        self.excludedIds = excludedIds
        self.onSelect    = onSelect
    }

    func roots(from all: Results<RInventory>) -> [RInventory] {
        all.filter { $0.common?.ownerId == $0.id && !excludedIds.contains($0.id) }
    }

    func children(of parent: RInventory) -> [RInventory] {
        parent.inventories.filter { !excludedIds.contains($0.id) }
    }
}

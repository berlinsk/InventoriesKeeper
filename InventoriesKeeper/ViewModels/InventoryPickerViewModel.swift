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
    
    private let user: User

    init(user: User, excludedIds: Set<ObjectId>, onSelect: @escaping (Inventory) -> Void) {
        self.user = user
        self.excludedIds = excludedIds
        self.onSelect = onSelect
    }

    func groupedRoots(for user: User) -> [(Game, [Inventory])] {
        user.games.compactMap { game in
            let roots = game.rootInventories.filter {
                $0.common?.ownerId == $0.id && !self.excludedIds.contains($0.id)
            }
            return roots.isEmpty ? nil : (game, Array(roots))
        }
    }

    func children(of parent: Inventory) -> [Inventory] {
        parent.inventories.filter { !excludedIds.contains($0.id) }
    }
}

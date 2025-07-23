//
//  InventoryPickerViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 15.07.2025.
//

import Foundation
import RealmSwift

enum InventoryPickerMode: Int, CaseIterable {
    case currentGame, userGames, global
}

final class InventoryPickerViewModel: ObservableObject {
    @Published var excludedIds: Set<ObjectId>
    @Published var mode: InventoryPickerMode = .currentGame

    let onSelect: (Inventory) -> Void
    
    private let user: User
    private let game: Game

    init(user: User, game: Game, excludedIds: Set<ObjectId>, onSelect: @escaping (Inventory) -> Void) {
        self.user = user
        self.game = game
        self.excludedIds = excludedIds
        self.onSelect = onSelect
    }

    func groupedRoots() -> [(User, Game, [Inventory])] {
        let realm = try! Realm()
        
        switch mode {
        case .currentGame:
            let roots = game.rootInventories.filter {
                $0.common?.ownerId == $0.id && !self.excludedIds.contains($0.id)
            }
            return roots.isEmpty ? [] : [(user, game, Array(roots))]

        case .userGames:
            return user.games.compactMap { game in
                let roots = game.rootInventories.filter {
                    $0.common?.ownerId == $0.id && !self.excludedIds.contains($0.id)
                }
                return roots.isEmpty ? nil : (user, game, Array(roots))
            }

        case .global:
            return realm.objects(User.self).flatMap { user in
                user.games.compactMap { game in
                    let roots = game.rootInventories.filter {
                        $0.common?.ownerId == $0.id && !self.excludedIds.contains($0.id)
                    }
                    return roots.isEmpty ? nil : (user, game, Array(roots))
                }
            }
        }
    }

    func children(of parent: Inventory) -> [Inventory] {
        parent.inventories.filter { !excludedIds.contains($0.id) }
    }
}

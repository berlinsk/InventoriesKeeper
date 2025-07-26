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

    func groupedRoots() -> [(User, Game?, [Inventory])] {
        let realm = try! Realm()

        switch mode {
        case .currentGame:
            let roots = allRoots(for: game, user: user)
                .filter { !self.excludedIds.contains($0.id) }
            return [(user, game, Array(roots))]

        case .userGames:
            if user.subscribedGames.isEmpty {
                return [(user, nil, [])]
            }
            return user.subscribedGames.compactMap { gameId -> (User, Game?, [Inventory])? in
                let realm = try! Realm()
                guard let g = realm.object(ofType: Game.self, forPrimaryKey: gameId) else { return nil }
                let roots = allRoots(for: g, user: user)
                    .filter { !self.excludedIds.contains($0.id) }
                return (user, g, roots)
            }

        case .global:
            return realm.objects(User.self).flatMap { user -> [(User, Game?, [Inventory])] in
                user.subscribedGames.compactMap { gameId -> (User, Game?, [Inventory])? in
                    guard let g = realm.object(ofType: Game.self, forPrimaryKey: gameId) else { return nil }
                    let roots = allRoots(for: g, user: user)
                        .filter { !self.excludedIds.contains($0.id) }
                    return (user, g, roots)
                }
            }
        }
    }

    func children(of parent: Inventory) -> [Inventory] {
        parent.inventories.filter { !excludedIds.contains($0.id) }
    }
    
    private func allRoots(for game: Game, user: User?) -> [Inventory] {
        let publics = Array(game.publicRootInventories)
        guard let u = user else { return publics }
        let privates = game.privateRootInventories.filter { $0.common?.ownerId == u.id }
        return publics + Array(privates)
    }
}

//
//  RootInventoryShareViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 26.07.2025.
//

import Foundation
import RealmSwift

final class RootInventoryShareViewModel: ObservableObject {
    @Published var rootInventories: [Inventory] = []
    @Published var selectedRootIds: Set<ObjectId> = []
    @Published var users: [User] = []
    @Published var selectedUserIds: Set<ObjectId> = []

    private let game: Game
    private let session: UserSession

    init(game: Game, session: UserSession) {
        self.game = game
        self.session = session
        loadData()
    }

    func loadData() {
        let realm = try! Realm()
        guard let liveGame = realm.object(ofType: Game.self, forPrimaryKey: game.id), let currentUser = session.user else { return }

        let ownedPrivate = Array(liveGame.privateRootInventories.filter {
            $0.common?.ownerId == currentUser.id
        })

        let sharedPublic = liveGame.publicRootInventories
            .compactMap { $0.user?.id == currentUser.id ? $0.inventory : nil }

        rootInventories = Array(Set(ownedPrivate + sharedPublic))

        users = GameRepository.participants(of: liveGame)
            .filter { $0.id != currentUser.id }
    }

    func toggleRootSelection(_ id: ObjectId) {
        if selectedRootIds.contains(id) {
            selectedRootIds.remove(id)
        } else {
            selectedRootIds.insert(id)
        }
    }

    func toggleUserSelection(_ id: ObjectId) {
        if selectedUserIds.contains(id) {
            selectedUserIds.remove(id)
        } else {
            selectedUserIds.insert(id)
        }
    }

    func shareSelectedRoots() {
        guard !selectedRootIds.isEmpty, !selectedUserIds.isEmpty else { return }

        let realm = try! Realm()
        guard let liveGame = realm.object(ofType: Game.self, forPrimaryKey: game.id) else { return }

        let rootInventories = selectedRootIds.compactMap { id in
            realm.object(ofType: Inventory.self, forPrimaryKey: id)
        }

        let usersToShare = selectedUserIds.compactMap { id in
            realm.object(ofType: User.self, forPrimaryKey: id)
        }

        try! realm.write {
            for user in usersToShare {
                for inventory in rootInventories {
                    let alreadyShared = liveGame.publicRootInventories.contains {
                        $0.user?.id == user.id && $0.inventory?.id == inventory.id
                    }
                    if !alreadyShared {
                        let shared = SharedRootInventory()
                        shared.user = user
                        shared.inventory = inventory
                        liveGame.publicRootInventories.append(shared)
                    }
                }
            }
        }

        for user in usersToShare {
            GameRepository.subscribe(user, to: liveGame)
        }

        loadData()
        selectedRootIds.removeAll()
        selectedUserIds.removeAll()
    }
}

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

        let sharedPublic = Array(liveGame.publicRootInventories)

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

        let rootIds  = Array(selectedRootIds)
        let userIds  = Array(selectedUserIds)
        
        try! realm.write {
            for userId in userIds {
                for rootId in rootIds {
                    let alreadyShared = liveGame.sharedRootAccess.contains {
                        $0.userId == userId && $0.inventoryId == rootId
                    }
                    if !alreadyShared {
                        let access = SharedRootAccess()
                        access.userId = userId
                        access.inventoryId = rootId
                        liveGame.sharedRootAccess.append(access)
                    }
                }
            }
        }
        
        let usersToSubscribe = Array(realm.objects(User.self).filter("id IN %@", userIds))
            for u in usersToSubscribe {
            GameRepository.subscribe(u, to: liveGame)
        }

        loadData()
        selectedRootIds.removeAll()
        selectedUserIds.removeAll()
    }
}

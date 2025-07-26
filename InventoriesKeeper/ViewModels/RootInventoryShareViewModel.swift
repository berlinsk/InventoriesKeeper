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

    init(game: Game) {
        self.game = game
        loadData()
    }

    func loadData() {
        let realm = try! Realm()
        guard let liveGame = realm.object(ofType: Game.self, forPrimaryKey: game.id) else { return }
        rootInventories = Array(liveGame.publicRootInventories) + Array(liveGame.privateRootInventories)
        let participants = liveGame.participantIds
        users = Array(realm.objects(User.self))
            .filter { participants.contains($0.id) && $0.id != liveGame.ownerId }
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
            let toShare = liveGame.privateRootInventories.filter { rootIds.contains($0.id) }

            for inv in toShare {
                if !liveGame.publicRootInventories.contains(inv) {
                    liveGame.publicRootInventories.append(inv)
                }
            }
            for inv in toShare {
                if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
                    liveGame.privateRootInventories.remove(at: idx)
                }
            }

            let realmUsers = realm.objects(User.self).filter("id IN %@", userIds)
            for u in realmUsers {
                if !u.subscribedGames.contains(liveGame.id) {
                    u.subscribedGames.append(liveGame.id)
                }
                if !liveGame.participantIds.contains(u.id) {
                    liveGame.participantIds.append(u.id)
                }
            }
        }

        loadData()
        selectedRootIds.removeAll()
        selectedUserIds.removeAll()
    }
}

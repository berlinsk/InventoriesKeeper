//
//  GameRepository.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import RealmSwift

enum GameRepository {
    static func allGames() -> [Game] {
        let realm = try! Realm()
        return Array(realm.objects(Game.self))
    }
    
    static func participants(of game: Game) -> [User] {
        let realm = try! Realm()
        return realm.objects(User.self)
            .filter { game.participantIds.contains($0.id) }
            .map { $0 }
    }
    
    static func rootInventories(of game: Game, for user: User) -> [Inventory] {
        let realm = try! Realm()

        let personal = Array(game.privateRootInventories.filter {
            $0.common?.ownerId == user.id
        })

        let publicShared = game.publicRootInventories
            .filter { $0.user?.id == user.id }
            .compactMap { $0.inventory }

        return Array(Set(personal + publicShared))
    }
    
    static func createRootInventory(for game: Game, user: User, name: String, kind: InventoryKind, isPublic: Bool, in realm: Realm) {
        let inv = SeedFactory.makeInventory(kind: kind, name: name, ownerId: user.id)
        realm.add(inv)

        if isPublic {
            let shared = SharedRootInventory()
            shared.user = user
            shared.inventory = inv
            game.publicRootInventories.append(shared)
        } else {
            game.privateRootInventories.append(inv)
        }
    }

    static func createGame(title: String, details: String?, isPublic: Bool, owner: User) -> Game {
        let realm = try! Realm()
        var obj: Game!
        try! realm.write {
            obj = Game()
            obj.id = .generate()
            obj.title = title
            obj.details = details
            obj.isPublic = isPublic

            obj.participantIds.append(owner.id)
            owner.subscribedGames.append(obj.id)
            realm.add(obj)

            createRootInventory(for: obj, user: owner, name: "Global Inventory", kind: .location, isPublic: true, in: realm)
            createRootInventory(for: obj, user: owner, name: "Main Character", kind: .character, isPublic: false, in: realm)
        }
        return obj
    }
    
    static func subscribe(_ user: User, to game: Game) {
        let realm = try! Realm()
        try! realm.write {
            _subscribe(user, to: game)
            
            let isNewParticipant = !game.privateRootInventories.contains(where: { inv in
                inv.kind == .character && inv.common?.ownerId == user.id
            })
            if isNewParticipant {
                createRootInventory(for: game, user: user, name: "Main Character", kind: .character, isPublic: false, in: realm)
            }
            
            let alreadySharedIds = Set(
                game.publicRootInventories
                    .filter { $0.user?.id == user.id }
                    .compactMap { $0.inventory?.id }
            )

            for shared in game.publicRootInventories {
                guard let inv = shared.inventory,
                      let sharedFromUserId = shared.user?.id,
                      sharedFromUserId != user.id,
                      !alreadySharedIds.contains(inv.id)
                else {
                    continue
                }

                let newShared = SharedRootInventory()
                newShared.user = user
                newShared.inventory = inv
                game.publicRootInventories.append(newShared)
            }
        }
    }
    
    static func _subscribe(_ user: User, to game: Game) {
        if !user.subscribedGames.contains(game.id) {
            user.subscribedGames.append(game.id)
        }
        if !game.participantIds.contains(user.id) {
            game.participantIds.append(user.id)
        }
    }
    
    static func unsubscribe(_ user: User, from game: Game) {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if let index = user.subscribedGames.firstIndex(of: game.id) {
                user.subscribedGames.remove(at: index)
            }
            if let index = game.participantIds.firstIndex(of: user.id) {
                game.participantIds.remove(at: index)
            }
        }
    }

    static func delete(game: Game) throws {
        let realm = try Realm()
        try realm.write {
            for shared in game.publicRootInventories {
                if let inv = shared.inventory {
                    TransferService.shared.deleteInventoryRecursively(inv, in: realm)
                }
            }

            for inv in game.privateRootInventories {
                TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            }

            game.publicRootInventories.removeAll()
            game.privateRootInventories.removeAll()
            
            realm.delete(game)
        }
    }
}

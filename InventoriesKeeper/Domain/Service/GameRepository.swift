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
    
    static func createRootInventory(for game: Game, user: User, type: RootInventoryType, in realm: Realm) {
        let inv = SeedFactory.makeInventory(kind: type.kind, name: type.name, ownerId: user.id)
        realm.add(inv)

        switch type {
        case .global:
            let shared = SharedRootInventory()
            shared.user = user
            shared.inventory = inv
            game.publicRootInventories.append(shared)
            game.globalInventory = inv

        case .mainCharacter:
            game.privateRootInventories.append(inv)
            game.mainCharacterInventories.append(inv)
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

            createRootInventory(for: obj, user: owner, type: .global, in: realm)
            createRootInventory(for: obj, user: owner, type: .mainCharacter, in: realm)
        }
        return obj
    }
    
    static func subscribe(_ user: User, to game: Game) {
        let realm = try! Realm()
        try! realm.write {
            _subscribe(user, to: game)
            
            if !game.mainCharacterInventories.contains(where: { $0.common?.ownerId == user.id }) {
                createRootInventory(for: game, user: user, type: .mainCharacter, in: realm)
            }
            
            if let global = game.globalInventory {
                let alreadyShared = game.publicRootInventories.contains {
                    $0.inventory?.id == global.id && $0.user?.id == user.id
                }
                if !alreadyShared {
                    let shared = SharedRootInventory()
                    shared.user = user
                    shared.inventory = global
                    game.publicRootInventories.append(shared)
                }
            } else {
                createRootInventory(for: game, user: user, type: .global, in: realm)
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

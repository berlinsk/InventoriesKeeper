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
       }
       return obj
   }

    static func subscribe(_ user: User, to game: Game) {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if !user.subscribedGames.contains(game.id) {
                user.subscribedGames.append(game.id)
            }
            if !game.participantIds.contains(user.id) {
                game.participantIds.append(user.id)
            }
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
            realm.delete(game.publicRootInventories)
            realm.delete(game.privateRootInventories)
            realm.delete(game)
        }
    }
}

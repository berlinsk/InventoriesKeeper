//
//  GameRepository.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import RealmSwift

enum GameRepository {
    static func allGames(for user: User) -> [Game] {
        return Array(user.games)
    }

    static func createGame(title: String, details: String?, isPublic: Bool, for user: User) -> Game {
        let realm = try! Realm()
        var obj: Game!
        try! realm.write {
            obj = Game()
            obj.id = .generate()
            obj.title = title
            obj.details = details
            obj.isPublic = isPublic

            user.games.append(obj)
            realm.add(obj)
        }
        return obj
    }

    static func delete(game: Game) throws {
        let realm = try Realm()
        try realm.write {
            realm.delete(game.rootInventories)
            realm.delete(game)
        }
    }
}

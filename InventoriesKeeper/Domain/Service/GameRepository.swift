//
//  GameRepository.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import RealmSwift

enum GameRepository {
    static func allGames(for user: User) -> [Game] {
        return user.games
    }

    static func createGame(title: String, details: String?, isPublic: Bool, for user: User) -> Game {
        let realm = try! Realm()
        var obj: RGame!
        try! realm.write {
            obj = RGame()
            obj.id = .generate()
            obj.title = title
            obj.details = details
            obj.isPublic = isPublic

            user.model.games.append(obj)
            realm.add(obj)
        }
        return Game(model: obj)
    }

    static func delete(game: Game) throws {
        let realm = try Realm()
        try realm.write {
            realm.delete(game.model.rootInventories)
            realm.delete(game.model)
        }
    }
}

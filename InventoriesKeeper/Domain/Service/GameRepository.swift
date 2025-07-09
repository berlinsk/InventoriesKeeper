//
//  GameRepository.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import RealmSwift

enum GameRepository {
    static func allGames(for user: RUser) -> [Game] {
        return user.games.map(Game.init)
    }

    static func createGame(title: String, details: String?, isPublic: Bool, for user: RUser) -> Game {
        let realm = try! Realm()
        var obj: RGame!
        try! realm.write {
            obj = RGame()
            obj.id = .generate()
            obj.title = title
            obj.details = details
            obj.isPublic = isPublic

            guard let liveUser = realm.object(ofType: RUser.self, forPrimaryKey: user.id) else {
                fatalError("User not found in current Realm")
            }

            liveUser.games.append(obj)
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

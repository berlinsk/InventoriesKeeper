//
//  UserSession.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import Foundation
import RealmSwift

final class UserSession: ObservableObject {
    @Published var username: String?
    @Published var isLoggedIn = false
    @Published var isAdmin = false
    var user: User?
    
    init() {
        let realm = try! Realm()
        
        if realm.objects(User.self).filter("username == 'admin'").first == nil {
            let admin = User()
            admin.id = .generate()
            admin.username = "admin"
            admin.password = "admin"
            admin.isAdmin = true
            admin.isLoggedIn = false

            try! realm.write {
                realm.add(admin)
            }
        }

        if let existingUser = realm.objects(User.self).filter("isLoggedIn == true").first {
            self.user = existingUser
            self.username = existingUser.username
            self.isAdmin = existingUser.isAdmin
            self.isLoggedIn = true
        }
    }
    
    func login(username: String, password: String) -> Bool {
        let realm = try! Realm()
        guard let existingUser = realm.objects(User.self).filter("username == %@", username).first,
              existingUser.password == password else {
            return false
        }
        
        try! realm.write {
            for user in realm.objects(User.self).filter("isLoggedIn == true") {
                user.isLoggedIn = false
            }
            existingUser.isLoggedIn = true
        }

        self.user = existingUser
        self.username = existingUser.username
        self.isAdmin = existingUser.isAdmin
        self.isLoggedIn = true
        return true
    }
    
    func register(username: String, password: String) -> Bool {
        let realm = try! Realm()
        if realm.objects(User.self).filter("username == %@", username).first != nil {
            return false
        }

        let newUser = User()
        newUser.id = .generate()
        newUser.username = username
        newUser.password = password
        newUser.isAdmin = (username == "admin")
        newUser.isLoggedIn = true

        try! realm.write {
            for user in realm.objects(User.self).filter("isLoggedIn == true") {
                user.isLoggedIn = false
            }
            realm.add(newUser)
        }

        self.user = newUser
        self.username = newUser.username
        self.isAdmin = newUser.isAdmin
        self.isLoggedIn = true
        return true
    }

    func logout() {
        let realm = try! Realm()
        try! realm.write {
            realm.objects(User.self)
                 .filter("isLoggedIn == true")
                 .setValue(false, forKey: "isLoggedIn")
        }
        clearSession()
    }

    func deleteCurrentUser() {
        guard let user = self.user else { return }
        let realm = try! Realm()

        try! realm.write {
            guard let liveUser = realm.object(ofType: User.self, forPrimaryKey: user.id) else { return }

            let gameIds = Array(liveUser.subscribedGames)
            for gid in gameIds {
                if let game = realm.object(ofType: Game.self, forPrimaryKey: gid) {
                    GameRepository.unsubscribeAndCleanup(liveUser, from: game, in: realm)
                }
            }

            realm.delete(liveUser)
        }

        clearSession()
    }

    func currentUser() -> User? {
        return self.user
    }
    
    private func clearSession() {
        self.username = nil
        self.isLoggedIn = false
        self.isAdmin = false
        self.user = nil
    }
}

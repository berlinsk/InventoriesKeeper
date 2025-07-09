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
    private var user: RUser?
    
    init() {
        if let savedUsername = UserDefaults.standard.string(forKey: "loggedInUser") {
            RealmConfig.configureForUser(username: savedUsername)
            
            let realm = try! Realm()
            if let existingUser = realm.objects(RUser.self).filter("username == %@", savedUsername).first {
                self.user = existingUser
                self.username = existingUser.username
                self.isAdmin = existingUser.isAdmin
                self.isLoggedIn = true
            }
        }
    }
    
    func login(username: String, password: String) -> Bool {
        let realm = try! Realm()
        if let existingUser = realm.objects(RUser.self).filter("username == %@", username).first,
           existingUser.password == password {
            self.user = existingUser
            self.username = existingUser.username
            self.isAdmin = existingUser.isAdmin
            self.isLoggedIn = true
            UserDefaults.standard.set(username, forKey: "loggedInUser")
            return true
        }
        return false
    }
    
    func register(username: String, password: String) -> Bool {
        let realm = try! Realm()
        if realm.objects(RUser.self).filter("username == %@", username).first != nil {
            return false
        }

        let newUser = RUser()
        newUser.id = .generate()
        newUser.username = username
        newUser.password = password
        newUser.isAdmin = (username == "admin")

        try! realm.write {
            realm.add(newUser)
        }

        self.user = newUser
        self.username = newUser.username
        self.isAdmin = newUser.isAdmin
        self.isLoggedIn = true
        UserDefaults.standard.set(username, forKey: "loggedInUser")
        return true
    }

    func logout() {
        self.username = nil
        self.isLoggedIn = false
        self.isAdmin = false
        self.user = nil
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
    }

    func currentUser() -> RUser? {
        let realm = try? Realm()
        guard let username = self.username else { return nil }
        return realm?.objects(RUser.self).filter("username == %@", username).first
    }
}

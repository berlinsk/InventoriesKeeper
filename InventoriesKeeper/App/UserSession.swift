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
        let realm = try! Realm()
        if let existingUser = realm.objects(RUser.self).filter("isLoggedIn == true").first {
            self.user = existingUser
            self.username = existingUser.username
            self.isAdmin = existingUser.isAdmin
            self.isLoggedIn = true
        }
    }
    
    func login(username: String, password: String) -> Bool {
        let realm = try! Realm()
        guard let existingUser = realm.objects(RUser.self).filter("username == %@", username).first,
              existingUser.password == password else {
            return false
        }
        
        try! realm.write {
            for user in realm.objects(RUser.self).filter("isLoggedIn == true") {
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
        if realm.objects(RUser.self).filter("username == %@", username).first != nil {
            return false
        }

        let newUser = RUser()
        newUser.id = .generate()
        newUser.username = username
        newUser.password = password
        newUser.isAdmin = (username == "admin")
        newUser.isLoggedIn = true

        try! realm.write {
            for user in realm.objects(RUser.self).filter("isLoggedIn == true") {
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
        guard let user = self.user else { return }
        let realm = try! Realm()
        try! realm.write {
            user.isLoggedIn = false
        }

        self.username = nil
        self.isLoggedIn = false
        self.isAdmin = false
        self.user = nil
    }

    func currentUser() -> RUser? {
        return self.user
    }
}

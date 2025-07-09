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
    
    init() {
        if let savedUsername = UserDefaults.standard.string(forKey: "loggedInUser") {
            self.username = savedUsername
            self.isLoggedIn = true
            RealmConfig.configureForUser(username: savedUsername)
        }
    }
    
    func login(username: String, password: String) -> Bool {
        let defaults = UserDefaults.standard
        let key = "user_\(username)_password"
        if let savedPassword = defaults.string(forKey: key),
           savedPassword == password {
            self.username = username
            self.isLoggedIn = true
            defaults.set(username, forKey: "loggedInUser")
            RealmConfig.configureForUser(username: username)
            return true
        }
        return false
    }
    
    func register(username: String, password: String) -> Bool {
        let defaults = UserDefaults.standard
        let key = "user_\(username)_password"
        if defaults.string(forKey: key) == nil {
            defaults.set(password, forKey: key)
            self.username = username
            self.isLoggedIn = true
            defaults.set(username, forKey: "loggedInUser")
            RealmConfig.configureForUser(username: username)
            return true
        }
        return false
    }
    
    func logout() {
        self.username = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
    }
}

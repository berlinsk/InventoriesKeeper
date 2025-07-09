//
//  AdminPanelView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI
import RealmSwift

struct AdminPanelView: View {
    @EnvironmentObject var session: UserSession
    @State private var users: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Users")) {
                    ForEach(users, id: \.self) { name in
                        Text(name)
                    }
                    .onDelete { idx in
                        idx.forEach { i in
                            deleteUser(named: users[i])
                        }
                        users = fetchUsers()
                    }
                }
            }
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { session.logout() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete ALL Data") {
                        confirmAndDeleteAllData()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Export Realm DB") {
                        exportRealm()
                    }
                }
            }
            .onAppear { users = fetchUsers() }
        }
    }

    private func fetchUsers() -> [String] {
        UserDefaults.standard.dictionaryRepresentation().keys
            .compactMap { $0.hasPrefix("user_") ? $0.replacingOccurrences(of: "user_", with: "").replacingOccurrences(of: "_password", with: "") : nil }
            .sorted()
    }

    private func deleteUser(named user: String) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "user_\(user)_password")

        let url = FileManager.documentsURL.appendingPathComponent("\(user).realm")
        
        let config = Realm.Configuration(fileURL: url,
                                         deleteRealmIfMigrationNeeded: true,
                                         objectTypes: [
                                             RGame.self,
                                             RItem.self,
                                             RInventory.self,
                                             ItemInventoryCommonFields.self,
                                             FoodItemDetails.self,
                                             LiquidItemDetails.self,
                                             BookItemDetails.self,
                                             WeaponItemDetails.self,
                                             CharacterInventoryDetails.self,
                                             LocationInventoryDetails.self,
                                             VehicleInventoryDetails.self,
                                             Weight.self,
                                             Currency.self,
                                             Volume.self,
                                             Calorie.self,
                                             GameDate.self
                                         ])
        do {
            let realm = try Realm(configuration: config)
            let games = realm.objects(RGame.self)
            
            try realm.write {
                for game in games {
                    for rootInv in game.rootInventories {
                        TransferService.shared.deleteInventoryRecursively(rootInv, in: realm)
                    }
                    realm.delete(game)
                }
            }
        } catch {
            print("Failed to cascade delete user \(user): \(error)")
        }

        FileManager.default.removeItemIfExists(at: url)
    }

    private func confirmAndDeleteAllData() {
        let alert = UIAlertController(
            title: "Delete ALL Data?",
            message: "This will permanently delete all user databases and the current database. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            deleteAllData()
        })
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    private func deleteAllData() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("user_") {
                let username = key.replacingOccurrences(of: "user_", with: "").replacingOccurrences(of: "_password", with: "")
                let url = FileManager.documentsURL.appendingPathComponent("\(username).realm")
                FileManager.default.removeItemIfExists(at: url)
            }
        }

        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("user_") || key == "loggedInUser" {
                defaults.removeObject(forKey: key)
            }
        }

        RealmResetService.reset()

        users = fetchUsers()
    }
    
    private func exportRealm() {
        guard let realmURL = Realm.Configuration.defaultConfiguration.fileURL else {
            print("Realm file URL not found")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [realmURL], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

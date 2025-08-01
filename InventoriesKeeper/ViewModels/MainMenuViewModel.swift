//
//  MainMenuViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 15.07.2025.
//

import Foundation
import RealmSwift
import SwiftUI

final class MainMenuViewModel: ObservableObject {
    @Published var worldInventory: Inventory?
    @Published var heroInventory: Inventory?
    @Published var pendingPushId: ObjectId?
    @Published var rootInventories: [Inventory] = []

    let gameModel: Game
    let session: UserSession

    init(game: Game, session: UserSession) {
        self.gameModel = game
        self.session = session
        loadRootInventories()
    }

    func logout() {
        session.logout()
    }
    
    private func allRootsForCurrentUser() -> [Inventory] {
        guard let currentUser = session.currentUser(),
              let realm = gameModel.realm else {
            return Array(gameModel.publicRootInventories)
        }

        let publics = Array(gameModel.publicRootInventories)

        let privates = gameModel.privateRootInventories.filter {
            $0.common?.ownerId == currentUser.id
        }

        let shared = gameModel.sharedRootAccess
            .filter { $0.userId == currentUser.id }
            .compactMap { access in
                realm.object(ofType: Inventory.self, forPrimaryKey: access.inventoryId)
            }

        return Array(Set(publics + Array(privates) + shared))
    }

    func loadRootInventories() {
        rootInventories = allRootsForCurrentUser()
    }

    func openOrCreateRoot(kind: InventoryKind, defaultName: String, path: Binding<NavigationPath>) {
        let all = allRootsForCurrentUser()
        if let rInv = all.first(where: { $0.kind == kind }) {
            path.wrappedValue.append(rInv)
        } else {
            createAndPushRoot(kind: kind, name: defaultName, isPublic: false)
        }
    }

    func createAndPushRoot(kind: InventoryKind, name: String, isPublic: Bool = false) {
        guard let liveGame = gameModel.thaw(),
              let realm = liveGame.realm else { return }

        var modelToOpen: Inventory!

        try! realm.write {
            let newInv = SeedFactory.makeInventory(
                kind: kind,
                name: name,
                ownerId: session.currentUser()?.id
            )
            realm.add(newInv)
            if isPublic {
                liveGame.publicRootInventories.append(newInv)
            } else {
                liveGame.privateRootInventories.append(newInv)
            }
            modelToOpen = newInv
        }
        
        loadRootInventories()
        pendingPushId = modelToOpen.id
    }

    func handleRootChange(path: Binding<NavigationPath>) {
        if let id = pendingPushId {
            let all = allRootsForCurrentUser()
            if let rInv = all.first(where: { $0.id == id }) {
                path.wrappedValue.append(rInv)
                pendingPushId = nil
            }
        }
        loadRootInventories()
    }

    func deleteRootInventory(at indexSet: IndexSet) {
        guard let realm = try? Realm(),
              let liveGame = gameModel.thaw() else { return }

        try? realm.write {
            for index in indexSet {
                let inv = rootInventories[index]

                if let idx = liveGame.publicRootInventories.firstIndex(of: inv) {
                    liveGame.publicRootInventories.remove(at: idx)
                } else if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
                    liveGame.privateRootInventories.remove(at: idx)
                }

                for i in (0..<liveGame.sharedRootAccess.count).reversed() {
                    if liveGame.sharedRootAccess[i].inventoryId == inv.id {
                        let access = liveGame.sharedRootAccess[i]
                        liveGame.sharedRootAccess.remove(at: i)
                        realm.delete(access)
                    }
                }

                TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            }
        }

        loadRootInventories()
    }

    func inventoryHierarchyDump() -> String {
        rootInventories
            .map { inventoryHierarchyString(for: $0) }
            .joined()
    }

    private func inventoryHierarchyString(for inventory: Inventory, indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = "\(indentString)• \(inventory.common?.name ?? "Unnamed") [\(inventory.kind.rawValue)]\n"
        for child in inventory.inventories {
            result += inventoryHierarchyString(for: child, indent: indent + 1)
        }
        return result
    }
}

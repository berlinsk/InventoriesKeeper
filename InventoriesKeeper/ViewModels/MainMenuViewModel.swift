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
            return gameModel.publicRootInventories.compactMap { $0.inventory }
        }

        let privates = Array(gameModel.privateRootInventories.filter {
            $0.common?.ownerId == currentUser.id
        })

        let sharedPublics = Array(gameModel.publicRootInventories
            .filter { $0.user?.id == currentUser.id }
            .compactMap { $0.inventory }
        )

        return Array(Set(privates + sharedPublics))
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
              let realm = liveGame.realm,
              let currentUser = session.currentUser() else { return }

        var modelToOpen: Inventory!

        try! realm.write {
            let newInv = SeedFactory.makeInventory(
                kind: kind,
                name: name,
                ownerId: currentUser.id
            )
            realm.add(newInv)

            if isPublic {
                let shared = SharedRootInventory()
                shared.user = currentUser
                shared.inventory = newInv
                liveGame.publicRootInventories.append(shared)
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

                if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
                    liveGame.privateRootInventories.remove(at: idx)
                }

                if let idx = liveGame.publicRootInventories.firstIndex(where: { $0.inventory?.id == inv.id }) {
                    let shared = liveGame.publicRootInventories[idx]
                    liveGame.publicRootInventories.remove(at: idx)
                    realm.delete(shared)
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

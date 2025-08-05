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
        guard let currentUser = session.currentUser() else {
            let globalId = gameModel.globalInventory?.id
            return Array(
                gameModel.publicRootInventories
                    .compactMap { $0.inventory }
                    .filter { $0.id != globalId }
            )
        }

        let globalId = gameModel.globalInventory?.id
        let mainCharacterIds = Set(
            gameModel.mainCharacterInventories
                .filter { $0.common?.ownerId == currentUser.id }
                .map { $0.id }
        )

        let privates = gameModel.privateRootInventories.filter {
            $0.common?.ownerId == currentUser.id &&
            $0.id != globalId &&
            !mainCharacterIds.contains($0.id)
        }

        let sharedPublics = gameModel.publicRootInventories
            .filter { $0.user?.id == currentUser.id }
            .compactMap { $0.inventory }
            .filter { $0.id != globalId && !mainCharacterIds.contains($0.id) }

        return Array(Set(Array(privates) + Array(sharedPublics)))
    }

    func loadRootInventories() {
        rootInventories = allRootsForCurrentUser()

        if let currentUser = session.currentUser() {
            worldInventory = gameModel.publicRootInventories.first(where: {
                $0.user?.id == currentUser.id && $0.inventory?.id == gameModel.globalInventory?.id
            })?.inventory
        } else {
            worldInventory = nil
        }

        if let user = session.currentUser() {
            heroInventory = gameModel.mainCharacterInventories.first { $0.common?.ownerId == user.id }
        } else {
            heroInventory = nil
        }
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
              let liveGame = gameModel.thaw(),
              let currentUser = session.currentUser() else { return }

        try? realm.write {
            for index in indexSet {
                let inv = rootInventories[index]
                deleteRootInventory(inv, realm: realm, liveGame: liveGame, currentUser: currentUser)
            }
        }

        loadRootInventories()
    }
    
    private func deleteRootInventory(_ inv: Inventory, realm: Realm, liveGame: Game, currentUser: User) {
        if let global = liveGame.globalInventory, inv.id == global.id {
            if let idx = liveGame.publicRootInventories.firstIndex(where: {
                $0.inventory?.id == global.id && $0.user?.id == currentUser.id
            }) {
                let shared = liveGame.publicRootInventories[idx]
                liveGame.publicRootInventories.remove(at: idx)
                realm.delete(shared)
            }
            loadRootInventories()
            return
        }

        if liveGame.mainCharacterInventories.contains(where: {
            $0.id == inv.id && $0.common?.ownerId == currentUser.id
        }) {
            if let idx = liveGame.mainCharacterInventories.firstIndex(of: inv) {
                liveGame.mainCharacterInventories.remove(at: idx)
            }
            if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
                liveGame.privateRootInventories.remove(at: idx)
            }
            TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            loadRootInventories()
            return
        }

        if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
            liveGame.privateRootInventories.remove(at: idx)
            TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            return
        }

        if let idx = liveGame.publicRootInventories.firstIndex(where: {
            $0.inventory?.id == inv.id && $0.user?.id == currentUser.id
        }) {
            let shared = liveGame.publicRootInventories[idx]
            liveGame.publicRootInventories.remove(at: idx)
            realm.delete(shared)

            let allShares = realm.objects(Game.self)
                .flatMap { $0.publicRootInventories }
                .filter { $0.inventory?.id == inv.id && $0.user?.id != currentUser.id }

            let stillPrivate = realm.objects(Game.self)
                .flatMap { $0.privateRootInventories }
                .contains { $0.id == inv.id && $0.common?.ownerId != currentUser.id }

            if allShares.isEmpty && !stillPrivate {
                TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            }
        }
    }
    
    func deleteSpecificInventory(_ inv: Inventory) {
        guard let realm = try? Realm(),
              let liveGame = gameModel.thaw(),
              let currentUser = session.currentUser() else { return }

        try? realm.write {
            deleteIfGlobalInventory(inv, realm: realm, liveGame: liveGame, currentUser: currentUser)
            deleteIfMainCharacterInventory(inv, realm: realm, liveGame: liveGame, currentUser: currentUser)
        }

        loadRootInventories()
    }

    private func deleteIfGlobalInventory(_ inv: Inventory, realm: Realm, liveGame: Game, currentUser: User) {
        if let global = liveGame.globalInventory, inv.id == global.id {
            if let idx = liveGame.publicRootInventories.firstIndex(where: {
                $0.inventory?.id == global.id && $0.user?.id == currentUser.id
            }) {
                let shared = liveGame.publicRootInventories[idx]
                liveGame.publicRootInventories.remove(at: idx)
                realm.delete(shared)
            }
            loadRootInventories()
            return
        }
    }

    private func deleteIfMainCharacterInventory(_ inv: Inventory, realm: Realm, liveGame: Game, currentUser: User) {
        if liveGame.mainCharacterInventories.contains(where: {
            $0.id == inv.id && $0.common?.ownerId == currentUser.id
        }) {
            if let idx = liveGame.mainCharacterInventories.firstIndex(of: inv) {
                liveGame.mainCharacterInventories.remove(at: idx)
            }
            if let idx = liveGame.privateRootInventories.firstIndex(of: inv) {
                liveGame.privateRootInventories.remove(at: idx)
            }
            TransferService.shared.deleteInventoryRecursively(inv, in: realm)
            loadRootInventories()
            return
        }
    }
    
    // test method
    func accessLabel(for inventory: Inventory) -> String {
        guard let currentUser = session.currentUser() else { return "Unknown" }

        if gameModel.privateRootInventories.contains(where: { $0.id == inventory.id && $0.common?.ownerId == currentUser.id }) {
            return "[private]"
        }

        if gameModel.publicRootInventories.contains(where: {
            $0.inventory?.id == inventory.id && $0.user?.id == currentUser.id
        }) {
            return "[shared]"
        }

        return "[unknown]"
    }

    func inventoryHierarchyDump() -> String {
        var result = ""

        if let world = worldInventory {
            result += "Global Inventory:\n"
            result += inventoryHierarchyString(for: world, indent: 1)
        }

        if let hero = heroInventory {
            result += "\nMain Character:\n"
            result += inventoryHierarchyString(for: hero, indent: 1)
        }

        if !rootInventories.isEmpty {
            result += "\nOther Root Inventories:\n"
            for inv in rootInventories {
                result += inventoryHierarchyString(for: inv, indent: 1)
            }
        }

        return result
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

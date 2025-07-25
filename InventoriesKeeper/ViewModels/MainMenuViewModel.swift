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

    func loadRootInventories() {
        rootInventories = Array(gameModel.rootInventories)
    }

    func openOrCreateRoot(kind: InventoryKind, defaultName: String, path: Binding<NavigationPath>) {
        if let rInv = gameModel.rootInventories.first(where: { $0.kind == kind }) {
            path.wrappedValue.append(rInv)
        } else {
            createAndPushRoot(kind: kind, name: defaultName)
        }
    }

    func createAndPushRoot(kind: InventoryKind, name: String) {
        guard let liveGame = gameModel.thaw(),
              let realm = liveGame.realm else { return }

        var modelToOpen: Inventory!

        try! realm.write {
            let newInv = SeedFactory.makeInventory(kind: kind, name: name)
            realm.add(newInv)
            liveGame.rootInventories.append(newInv)
            modelToOpen = newInv
        }

        pendingPushId = modelToOpen.id
    }

    func handleRootChange(path: Binding<NavigationPath>) {
        if let id = pendingPushId,
           let rInv = gameModel.rootInventories.first(where: { $0.id == id }) {
            path.wrappedValue.append(rInv)
            pendingPushId = nil
        }
        loadRootInventories()
    }

    func deleteRootInventory(at indexSet: IndexSet) {
        guard let realm = try? Realm(),
              let liveGame = gameModel.thaw() else { return }

        try? realm.write {
            for index in indexSet {
                let inv = rootInventories[index]
                TransferService.shared.deleteInventoryRecursively(inv, in: realm)
                if let idxInList = liveGame.rootInventories.firstIndex(of: inv) {
                    liveGame.rootInventories.remove(at: idxInList)
                }
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

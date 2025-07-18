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

    let gameModel: RGame
    let session: UserSession

    init(game: Game, session: UserSession) {
        self.gameModel = game.model
        self.session = session
        loadRootInventories()
    }

    func logout() {
        session.logout()
    }

    func loadRootInventories() {
        rootInventories = gameModel.rootInventories.map(Inventory.init)
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

        var modelToOpen: RInventory!

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
        for index in indexSet {
            try? rootInventories[index].deleteRecursively()
        }
        loadRootInventories()
    }

    func inventoryHierarchyDump() -> String {
        rootInventories
            .map { inventoryHierarchyString(for: $0.model) }
            .joined()
    }

    private func inventoryHierarchyString(for inventory: RInventory, indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = "\(indentString)• \(inventory.common?.name ?? "Unnamed") [\(inventory.kind.rawValue)]\n"
        for child in inventory.inventories {
            result += inventoryHierarchyString(for: child, indent: indent + 1)
        }
        return result
    }
}

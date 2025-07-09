//
//  ContentView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI
import RealmSwift

struct MainMenuView: View {
    @EnvironmentObject var session: UserSession
    @ObservedRealmObject private var gameModel: RGame
    @Binding var path: NavigationPath
    @State private var worldInventory: Inventory?
    @State private var heroInventory: Inventory?
    @State private var pendingPushId: ObjectId?
    
    // for test
    private var inventoryHierarchyDump: String {
        rootInventories
            .map { inventoryHierarchyString(for: $0.model) }
            .joined()
    }
    
    private var rootInventories: [Inventory] {
        gameModel.rootInventories.map(Inventory.init)
    }
    
    init(game: Game, path: Binding<NavigationPath>) {
        self._gameModel = ObservedRealmObject(wrappedValue: game.model)
        self._path = path
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("Logout") {
                session.logout()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            Button("Global Inv") {
                openOrCreateRoot(kind: .location, defaultName: "Global inv")
            }
            .buttonStyle(.borderedProminent)
            
            Button("Main character") {
                openOrCreateRoot(kind: .character, defaultName: "Main character")
            }
            .buttonStyle(.borderedProminent)
            
            Button("+ Add root inv") {
                createAndPushRoot(kind: .generic, name: "Root \(Int.random(in: 1...999))")
            }
            .buttonStyle(.bordered)
            
            Divider().padding(.vertical, 8)
            
            Text("Root Inventories:")
                .font(.headline)
            
            List {
                ForEach(rootInventories, id: \.id) { inv in
                    Button(inv.name) { path.append(inv.model) }
                }
                .onDelete { idx in
                    idx.forEach { i in
                        try? rootInventories[i].deleteRecursively()
                    }
                }
            }
            .frame(height: 300)
            
            // for test
            ScrollView {
                Text(inventoryHierarchyDump)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .padding()
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .navigationTitle("Menu")
        .navigationDestination(for: RInventory.self) { rInv in
            InventoryDomainView(invModel: rInv)
        }
        .onChange(of: gameModel.rootInventories.count) { _ in
            if let id = pendingPushId,
               let rInv = gameModel.rootInventories.first(where: { $0.id == id }) {
                path.append(rInv)
                pendingPushId = nil
            }
        }
        .navigationDestination(for: RInventory.self) { rInv in
            InventoryDomainView(invModel: rInv)
        }
    }
    
    func openOrCreateRoot(kind: InventoryKind, defaultName: String) {
        if let rInv = gameModel.rootInventories.first(where: { $0.kind == kind }) {
            path.append(rInv)
        } else {
            createAndPushRoot(kind: kind, name: defaultName)
        }
    }
    
    func createAndPushRoot(kind: InventoryKind, name: String) {
        guard let liveGame = gameModel.thaw(),
              let realm    = liveGame.realm else { return }

        var modelToOpen: RInventory!

        try! realm.write {
            let newInv = SeedFactory.makeInventory(kind: kind, name: name)
            realm.add(newInv)
            liveGame.rootInventories.append(newInv)
            modelToOpen = newInv
        }

        pendingPushId = modelToOpen.id
    }


    func inventoryString(for inv: RInventory, indent: Int = 0) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var res = "\(indentStr)• \(inv.common?.name ?? "Unnamed") [\(inv.kind.rawValue)]\n"
        for child in inv.inventories {
            res += inventoryString(for: child, indent: indent + 1)
        }
        return res
    }
    
    // for test
    private func inventoryHierarchyString(for inventory: RInventory, indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = "\(indentString)• \(inventory.common?.name ?? "Unnamed") [\(inventory.kind.rawValue)]\n"
        for child in inventory.inventories {
            result += inventoryHierarchyString(for: child, indent: indent + 1)
        }
        return result
    }
}

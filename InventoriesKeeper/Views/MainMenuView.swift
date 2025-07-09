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
    @State private var path = NavigationPath()
    @State private var rootInventories: [Inventory] = []
    @State private var worldInventory: Inventory?
    @State private var heroInventory: Inventory?
    
    // for test
    private var inventoryHierarchyDump: String {
        rootInventories
            .map { inventoryHierarchyString(for: $0.model) }
            .joined()
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Button("Logout") {
                    session.logout()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                Button("Global Inv") {
                    if let inv = Inventory.findRoot(kind: .location) {
                        worldInventory = inv
                        path.append(inv.model)
                    } else {
                        let inv = Inventory.createRoot(kind: .location, name: "Global inv")
                        worldInventory = inv
                        path.append(inv.model)
                        rootInventories = Inventory.getAllRoots()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Main character") {
                    if let inv = Inventory.findRoot(kind: .character) {
                        heroInventory = inv
                        path.append(inv.model)
                    } else {
                        let inv = Inventory.createRoot(kind: .character, name: "Main character")
                        heroInventory = inv
                        path.append(inv.model)
                        rootInventories = Inventory.getAllRoots()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("+ Add root inv") {
                    let inv = Inventory.createRoot(kind: .generic, name: "Root \(Int.random(in: 1...999))")
                    rootInventories = Inventory.getAllRoots()
                    path.append(inv.model)
                }
                .buttonStyle(.bordered)

                Divider().padding(.vertical, 8)

                Text("Root Inventories:")
                    .font(.headline)

                List {
                    ForEach(rootInventories, id: \.id) { inv in
                        Button(inv.name) {
                            path.append(inv.model)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let inv = rootInventories[index]
                            try? inv.deleteRecursively()
                        }
                        rootInventories = Inventory.getAllRoots()
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
            .onAppear {
                rootInventories = Inventory.getAllRoots()
            }
            .navigationTitle("Menu")
            .navigationDestination(for: RInventory.self) { rInv in
                InventoryDomainView(invModel: rInv)
            }
        }
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

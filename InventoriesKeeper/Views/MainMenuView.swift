//
//  ContentView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI
import RealmSwift

struct MainMenuView: View {
    @ObservedResults(RInventory.self) var allInventories

    @State private var path = NavigationPath()
    @State private var worldInventory: RInventory?
    @State private var heroInventory: RInventory?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Button("Global Inv") {
                    let realm = try! Realm()
                    if let existing = realm.objects(RInventory.self).filter("kind == %@", InventoryKind.location.rawValue).first {
                        worldInventory = existing
                        path.append(existing)
                    } else {
                        try! realm.write {
                            let inv = SeedFactory.makeInventory(kind: .location, name: "Global inv")
                            realm.add(inv)
                            worldInventory = inv
                            path.append(inv)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Main character") {
                    let realm = try! Realm()
                    if let existing = realm.objects(RInventory.self).filter("kind == %@", InventoryKind.character.rawValue).first {
                        heroInventory = existing
                        path.append(existing)
                    } else {
                        try! realm.write {
                            let inv = SeedFactory.makeInventory(kind: .character, name: "Main character")
                            realm.add(inv)
                            heroInventory = inv
                            path.append(inv)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("+ Add root inv") {
                    let inv = SeedFactory.addRootInventory()
                    path.append(inv)
                }
                .buttonStyle(.bordered)

                Divider().padding(.vertical, 8)

                Text("Root Inventories:")
                    .font(.headline)

                List {
                    ForEach(allInventories) { inv in
                        Button(inv.common?.name ?? "Unnamed root") {
                            path.append(inv)
                        }
                    }
                    .onDelete { indexSet in
                        let realm = try! Realm()
                        try! realm.write {
                            indexSet.forEach { index in
                                let inv = allInventories[index]
                                if let liveInv = inv.thaw() {
                                    realm.delete(liveInv)
                                }
                            }
                        }
                    }
                }
                .frame(height: 300)
            }
            .padding()
            .navigationTitle("Menu")
            .onAppear {
                setupRootInventoriesIfNeeded()
            }
            .navigationDestination(for: RInventory.self) { rInv in
                InventoryDomainView(invModel: rInv)
            }
        }
    }

    private func setupRootInventoriesIfNeeded() {
        let realm = try! Realm()

        if worldInventory == nil {
            if let existing = realm.objects(RInventory.self).filter("kind == %@", InventoryKind.location.rawValue).first {
                worldInventory = existing
            } else {
                try! realm.write {
                    let inv = SeedFactory.makeInventory(kind: .location, name: "Global inv")
                    realm.add(inv)
                    worldInventory = inv
                }
            }
        }

        if heroInventory == nil {
            if let existing = realm.objects(RInventory.self).filter("kind == %@", InventoryKind.character.rawValue).first {
                heroInventory = existing
            } else {
                try! realm.write {
                    let inv = SeedFactory.makeInventory(kind: .character, name: "Main character")
                    realm.add(inv)
                    heroInventory = inv
                }
            }
        }
    }
}

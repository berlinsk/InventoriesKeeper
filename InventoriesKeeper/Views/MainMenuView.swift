//
//  ContentView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI
import RealmSwift

struct MainMenuView: View {
    @StateObject private var vm: MainMenuViewModel
    @Binding var path: NavigationPath
    @State private var showingShare = false

    init(game: Game, session: UserSession, path: Binding<NavigationPath>) {
        _vm = StateObject(wrappedValue: MainMenuViewModel(game: game, session: session))
        self._path = path
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("Logout") {
                vm.logout()
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button("Global Inv") {
                vm.openOrCreateRoot(kind: .location, defaultName: "Global inv", path: $path)
            }
            .buttonStyle(.borderedProminent)

            Button("Main character") {
                vm.openOrCreateRoot(kind: .character, defaultName: "Main character", path: $path)
            }
            .buttonStyle(.borderedProminent)

            Button("+ Add root inv") {
                vm.createAndPushRoot(kind: .generic, name: "Root \(Int.random(in: 1...999))", isPublic: false)
            }
            .buttonStyle(.bordered)
            
            Button("Share Roots") {
                showingShare = true
            }
            .buttonStyle(.borderedProminent)

            Divider().padding(.vertical, 8)

            Text("Root Inventories:")
                .font(.headline)

            List {
                if let global = vm.worldInventory {
                    Section("Global Inventory") {
                        Button("\(vm.accessLabel(for: global)) \(global.common?.name ?? "Unnamed")") {
                            path.append(global)
                        }
                    }
                }

                if let hero = vm.heroInventory {
                    Section("Main Character") {
                        Button("\(vm.accessLabel(for: hero)) \(hero.common?.name ?? "Unnamed")") {
                            path.append(hero)
                        }
                    }
                }

                let others = vm.rootInventories.filter { inv in
                    inv.id != vm.worldInventory?.id &&
                    inv.id != vm.heroInventory?.id
                }

                if !others.isEmpty {
                    Section("Other Inventories") {
                        ForEach(others, id: \.id) { inv in
                            Button("\(vm.accessLabel(for: inv)) \(inv.common?.name ?? "Unnamed")") {
                                path.append(inv)
                            }
                        }
                        .onDelete(perform: vm.deleteRootInventory)
                    }
                }
            }
            .frame(height: 200)

            ScrollView {
                Text(vm.inventoryHierarchyDump())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .padding()
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .navigationTitle("Menu")
        .navigationDestination(for: Inventory.self) { rInv in
            InventoryDomainView(gameModel: vm.gameModel, invModel: rInv)
        }
        .onChange(of: vm.rootInventories.count) { _ in
            vm.handleRootChange(path: $path)
        }
        .sheet(isPresented: $showingShare) {
            RootInventoryShareView(game: vm.gameModel, session: vm.session)
        }
    }
}

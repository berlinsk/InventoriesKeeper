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

            Divider().padding(.vertical, 8)

            Text("Root Inventories:")
                .font(.headline)

            List {
                ForEach(vm.rootInventories, id: \.id) { inv in
                    Button(inv.common?.name ?? "Unnamed") {
                        path.append(inv)
                    }
                }
                .onDelete(perform: vm.deleteRootInventory)
            }
            .frame(height: 300)

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
    }
}

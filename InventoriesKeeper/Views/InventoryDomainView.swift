//
//  InventoryDomainView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import SwiftUI
import RealmSwift

struct AlertText: Identifiable {
    let id = UUID()
    let text: String
}

struct InventoryDomainView: View {
    @ObservedRealmObject var invModel: Inventory
    @StateObject private var viewModel = InventoryDomainViewModel()

    @State private var errorText: AlertText?
    @State private var selection: Set<ObjectId> = []
    @State private var showPicker = false
    @Environment(\.editMode) private var editMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tot. weight: \(invModel.totalWeight.value, specifier: "%.2f") \(invModel.totalWeight.unit.rawValue)")
                .font(.subheadline)
                .padding(.horizontal)

            List(selection: $selection) {
                itemsSection()
                inventoriesSection()
                buttonsSection()
            }
            .alert(item: $viewModel.errorText) { alert in
                Alert(title: Text(alert.text))
            }
            .navigationTitle(invModel.common?.name ?? "Unnamed")
        }
        .navigationTitle(invModel.common?.name ?? "Unnamed")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .bottomBar) {
                if editMode?.wrappedValue.isEditing == true {
                    Button("Move Selected") {
                        showPicker = true
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            InventoryPickerView(
                excludedIds: viewModel.computeExcludedIds(selection: selection, from: invModel),
                onSelect: { destinationInventory in
                    viewModel.moveSelected(selection: selection, from: invModel, to: destinationInventory)
                    selection.removeAll()
                    showPicker = false
                }
            )
        }
    }

    @ViewBuilder
    private func itemsSection() -> some View {
        Section("Items") {
            ForEach(invModel.items, id: \.id) { rItem in
                Text("\(rItem.common?.name ?? "Unnamed") | \(rItem.kind.rawValue)")
            }
            .onDelete { idx in
                viewModel.delete(at: idx, isItem: true, from: invModel)
            }
        }
    }

    @ViewBuilder
    private func inventoriesSection() -> some View {
        Section("Inventories") {
            ForEach(invModel.inventories, id: \.id) { rInv in
                NavigationLink(destination: InventoryDomainView(invModel: rInv)) {
                    Text("\(rInv.common?.name ?? "Unnamed") | \(rInv.kind.rawValue)")
                }
            }
            .onDelete { idx in
                viewModel.delete(at: idx, isItem: false, from: invModel)
            }
        }
    }

    @ViewBuilder
    private func buttonsSection() -> some View {
        Section {
            Button("Add food item") {
                viewModel.addItem(kind: .food, name: "apple", to: invModel)
            }
            Button("Add liquid item") {
                viewModel.addItem(kind: .liquid, name: "water", to: invModel)
            }
            Button("Add weapon item") {
                viewModel.addItem(kind: .weapon, name: "ar4", to: invModel)
            }
            Button("Add book item") {
                viewModel.addItem(kind: .book, name: "book", to: invModel)
            }
            Divider()
            Button("Add character inv") {
                viewModel.addInventory(kind: .character, name: "npc", to: invModel)
            }
            Button("Add location inv") {
                viewModel.addInventory(kind: .location, name: "cave", to: invModel)
            }
            Button("Add vehicle inv") {
                viewModel.addInventory(kind: .vehicle, name: "car", to: invModel)
            }
        }
    }
}

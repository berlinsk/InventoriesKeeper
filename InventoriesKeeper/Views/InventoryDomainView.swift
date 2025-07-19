//
//  InventoryDomainView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import SwiftUI
import RealmSwift

enum SeedFactory {
    static func makeInventory(kind: InventoryKind, name: String, ownerId: ObjectId? = nil) -> Inventory {
        let inv = Inventory()
        inv.id = ObjectId.generate()
        let common = ItemInventoryCommonFields()
        common.name = name
        common.ownerId = ownerId ?? inv.id
        common.weight = Weight(value: Double.random(in: 5...20), unit: .kg)
        common.createdAt = Date()
        inv.common = common
        inv.kind = kind
        return inv
    }

    static func addRootInventory() -> Inventory {
        let realm = try! Realm()
        let inv = makeInventory(kind: .generic, name: "Root \(Int.random(in: 1...999))")
        try! realm.write {
            realm.add(inv)
        }
        return inv
    }


    static func makeItem(kind: ItemKind, name: String, ownerId: ObjectId) -> Item {
        let item = Item()
        item.id = ObjectId.generate()
        let common = ItemInventoryCommonFields()
        common.name      = name
        common.ownerId   = ownerId
        common.weight    = Weight(value: Double.random(in: 0.1...3000), unit: .kg)
        common.createdAt = Date()
        item.common = common
        item.kind   = kind
        return item
    }
}

struct AlertText: Identifiable {
    let id = UUID()
    let text: String
}

struct InventoryDomainView: View {
    @ObservedRealmObject var invModel: Inventory
    private var inventory: Inventory { invModel }
    @State private var errorText: AlertText?
    @State private var selection: Set<ObjectId> = []
    @State private var showPicker = false
    @Environment(\.editMode) private var editMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tot. weight: \(inventory.totalWeight.value, specifier: "%.2f") \(inventory.totalWeight.unit.rawValue)")
                .font(.subheadline)
                .padding(.horizontal)

            List(selection: $selection) {
                itemsSection()
                inventoriesSection()
                buttonsSection()
            }
            .alert(item: $errorText) { alert in
                Alert(title: Text(alert.text))
            }
            .navigationTitle(inventory.common?.name ?? "Unnamed")
        }
        .navigationTitle(inventory.common?.name ?? "Unnamed")
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
                excludedIds: computeExcludedIds(),
                onSelect: { destinationInventory in
                    moveSelected(to: destinationInventory)
                    showPicker = false
                }
            )
        }
    }
    
    @ViewBuilder
    private func itemsSection() -> some View {
        Section("Items") {
            ForEach(inventory.items, id: \.id) { rItem in
                Text("\(rItem.common?.name ?? "Unnamed") | \(rItem.kind.rawValue)")
            }
            .onDelete { idx in delete(at: idx, isItem: true) }
        }
    }

    @ViewBuilder
    private func inventoriesSection() -> some View {
        Section("Inventories") {
            ForEach(inventory.inventories, id: \.id) { rInv in
                NavigationLink(destination: InventoryDomainView(invModel: rInv)) {
                    Text("\(rInv.common?.name ?? "Unnamed") | \(rInv.kind.rawValue)")
                }
            }
            .onDelete { idx in delete(at: idx, isItem: false) }
        }
    }

    @ViewBuilder
    private func buttonsSection() -> some View {
        Section {
            Button("Add food item"){
                addItem(kind: .food, name: "apple")
            }
            Button("Add liquid item"){
                addItem(kind: .liquid, name: "water")
            }
            Button("Add weapon item"){
                addItem(kind: .weapon, name: "ar4")
            }
            Button("Add book item"){
                addItem(kind: .book, name: "book")
            }
            Divider()
            Button("Add character inv"){
                addInventory(kind: .character, name: "npc")
            }
            Button("Add location inv"){
                addInventory(kind: .location, name: "cave")
            }
            Button("Add vehicle inv"){
                addInventory(kind: .vehicle, name: "car")
            }
        }
    }

    private func addItem(kind: ItemKind, name: String) {
        let realm = try! Realm()
        let item = SeedFactory.makeItem(kind: kind, name: name, ownerId: inventory.id)
        DispatchQueue.main.async {
            do {
                try TransferService.shared.add(item: item, to: inventory, in: realm)
            } catch {
                errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    private func addInventory(kind: InventoryKind, name: String) {
        let inv = Inventory.createChild(kind: kind, name: name, ownerId: inventory.id)
        let realm = try! Realm()
        DispatchQueue.main.async {
            do {
                try TransferService.shared.add(inventory: inv, to: inventory, in: realm)
            } catch {
                errorText = AlertText(text: error.localizedDescription)
            }
        }
    }
    
    private func moveSelected(to destination: Inventory) {
        DispatchQueue.main.async {
            do {
                let destId = destination.id
                for id in selection {
                    if inventory.items.contains(where: { $0.id == id }) {
                        try TransferService.shared.moveItem(withId: id, to: destId)
                    }
                    else if inventory.inventories.contains(where: { $0.id == id }) {
                        try TransferService.shared.moveInventory(withId: id, to: destId)
                    }
                }
                selection.removeAll()
                editMode?.animation().wrappedValue = .inactive
            } catch {
                errorText = AlertText(text: error.localizedDescription)
            }
        }
    }
    
    private func computeExcludedIds() -> Set<ObjectId> {
        var excluded: Set<ObjectId> = []
        for id in selection {
            if let rInv = inventory.inventories.first(where: { $0.id == id }) {
                excluded.insert(rInv.id)
                collectChildIds(of: rInv, into: &excluded)
            }
        }
        return excluded
    }

    private func collectChildIds(of inventory: Inventory, into set: inout Set<ObjectId>) {
        for child in inventory.inventories {
            set.insert(child.id)
            collectChildIds(of: child, into: &set)
        }
    }

    private func delete(at indexSet: IndexSet, isItem: Bool) {
        for idx in indexSet {
            if isItem {
                let rItem = inventory.items[idx]
                let realm = try! Realm()
                do {
                    try TransferService.shared.remove(item: rItem, from: inventory, in: realm)
                }
                catch { errorText = AlertText(text: error.localizedDescription) }
            } else {
                let rInv = inventory.inventories[idx]
                let realm = try! Realm()
                do {
                    try TransferService.shared.remove(inventory: rInv, from: inventory, in: realm)
                }
                catch { errorText = AlertText(text: error.localizedDescription) }
            }
        }
    }
}

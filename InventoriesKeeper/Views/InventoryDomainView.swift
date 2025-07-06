//
//  InventoryDomainView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 04.07.2025.
//

import SwiftUI
import RealmSwift

enum SeedFactory {
    static func makeInventory(kind: InventoryKind, name: String, ownerId: ObjectId? = nil) -> RInventory {
        let inv = RInventory()
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

    static func addRootInventory() -> RInventory {
        let realm = try! Realm()
        let inv = makeInventory(kind: .generic, name: "Root \(Int.random(in: 1...999))")
        try! realm.write {
            realm.add(inv)
        }
        return inv
    }


    static func makeItem(kind: ItemKind, name: String, ownerId: ObjectId) -> RItem {
        let item = RItem()
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
    @ObservedRealmObject var invModel: RInventory
    private var inventory: Inventory { Inventory(model: invModel) }

    @State private var errorText: AlertText?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tot. weight: \(inventory.totalWeight.value, specifier: "%.2f") \(inventory.totalWeight.unit.rawValue)")
                .font(.subheadline)
                .padding(.horizontal)

            List {
                Section("Items") {
                    ForEach(invModel.items) { rItem in
                        Text("\(rItem.common?.name ?? "Unnamed") | \(rItem.kind.rawValue)")
                    }
                    .onDelete { idx in delete(at: idx, isItem: true) }
                }

                Section("Inventories") {
                    ForEach(invModel.inventories) { rInv in
                        NavigationLink(destination: InventoryDomainView(invModel: rInv)) {
                            Text(rInv.common?.name ?? "Unnamed") +
                            Text(" | \(rInv.kind.rawValue)")
                        }
                    }
                    .onDelete { idx in delete(at: idx, isItem: false) }
                }

                Section {
                    Button("Add food itm"){
                        addItem(kind: .food, name: "apple")
                    }
                    Button("Add book itm"){
                        addItem(kind: .liquid, name: "water")
                    }
                    Button("Add weapon itm"){
                        addItem(kind: .weapon, name: "ar4")
                    }
                    Button("Add book itm"){
                        addItem(kind: .book, name: "book")
                    }
                    Divider()
                    Button("Add character inv"){
                        addInventory(kind: .character, name: "npc")
                    }
                    Button("Add location inv"){
                        addInventory(kind: .location,  name: "cave")
                    }
                    Button("Add vehicle inv"){
                        addInventory(kind: .vehicle,   name: "car")
                    }
                }
            }
            .alert(item: $errorText) { alert in
                Alert(title: Text(alert.text))
            }
            .navigationTitle(invModel.common?.name ?? "inventory")
            .alert(item: $errorText) { alert in
                Alert(title: Text(alert.text))
            }
        }
        .navigationTitle(invModel.common?.name ?? "inventory")
    }

    private func addItem(kind: ItemKind, name: String) {
        let rItem = SeedFactory.makeItem(kind: kind, name: name, ownerId: invModel.id)
        let item  = Item(model: rItem)
        DispatchQueue.main.async {
            do {
                try inventory.add(object: item)
            } catch {
                errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    private func addInventory(kind: InventoryKind, name: String) {
        let rInv = SeedFactory.makeInventory(kind: kind, name: name, ownerId: invModel.id)
        let inv  = Inventory(model: rInv)
        DispatchQueue.main.async {
            do {
                try inventory.add(object: inv)
            } catch {
                errorText = AlertText(text: error.localizedDescription)
            }
        }
    }

    private func delete(at indexSet: IndexSet, isItem: Bool) {
        for idx in indexSet {
            if isItem {
                let rItem = invModel.items[idx]
                do { try inventory.remove(object: Item(model: rItem)) }
                catch { errorText = AlertText(text: error.localizedDescription) }
            } else {
                let rInv = invModel.inventories[idx]
                do { try inventory.remove(object: Inventory(model: rInv)) }
                catch { errorText = AlertText(text: error.localizedDescription) }
            }
        }
    }

}

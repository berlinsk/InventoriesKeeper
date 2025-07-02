//
//  ContentView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 30.06.2025.
//

import SwiftUI
import RealmSwift

class Test: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
}

struct RootView: View {
    @ObservedResults(Test.self) var items

    var body: some View {
        VStack {
            Button("add") {
                let newItem = Test()
                newItem.name = "test \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))"
                $items.append(newItem)
            }
            .padding()

            List {
                ForEach(items) { item in
                    Text(item.name)
                }
            }
        }
    }
}

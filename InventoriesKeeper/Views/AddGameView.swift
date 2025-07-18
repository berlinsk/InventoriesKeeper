//
//  AddGameView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct AddGameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: AddGameViewModel
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("New Game") {
                    TextField("Title", text: $vm.title)
                    TextField("Description", text: $vm.details)
                    Toggle("Public game", isOn: $vm.isPublic)
                }
            }
            .navigationTitle("Add Game")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.saveGame()
                        onDone()
                    }
                    .disabled(vm.title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

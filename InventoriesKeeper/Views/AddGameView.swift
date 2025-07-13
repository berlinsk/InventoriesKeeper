//
//  AddGameView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct AddGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var isPublic = false
    let user: User
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("New Game") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $details)
                    Toggle("Public game", isOn: $isPublic)
                }
            }
            .navigationTitle("Add Game")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = GameRepository.createGame(
                            title: title,
                            details: details.isEmpty ? nil : details,
                            isPublic: isPublic,
                            for: user
                        )
                        onDone()
                    }.disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

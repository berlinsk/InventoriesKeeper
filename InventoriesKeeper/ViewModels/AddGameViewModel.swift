//
//  AddGameViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 14.07.2025.
//

import Foundation

final class AddGameViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var details: String = ""
    @Published var isPublic: Bool = false

    private let user: User

    init(user: User) {
        self.user = user
    }

    func saveGame() {
        _ = GameRepository.createGame(
            title: title,
            details: details.isEmpty ? nil : details,
            isPublic: isPublic,
            owner: user
        )
    }
}

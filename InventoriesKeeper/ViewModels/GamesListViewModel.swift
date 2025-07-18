//
//  GamesListViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 14.07.2025.
//

import Foundation
import SwiftUI

final class GamesListViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var showAdd: Bool = false
    @Published var navPath = NavigationPath()

    private let session: UserSession

    init(session: UserSession) {
        self.session = session
        loadGames()
    }

    func loadGames() {
        if let user = session.currentUser() {
            games = GameRepository.allGames(for: user)
        }
    }

    func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            try? GameRepository.delete(game: games[index])
        }
        loadGames()
    }

    func currentUser() -> User? {
        session.currentUser()
    }

    func logout() {
        session.logout()
    }
}

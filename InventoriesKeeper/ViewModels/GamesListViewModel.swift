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
    @Published var availableGames: [Game] = []
    @Published var showAdd: Bool = false
    @Published var navPath = NavigationPath()

    private let session: UserSession

    init(session: UserSession) {
        self.session = session
        loadGames()
    }

    func loadGames() {
        guard let user = session.currentUser() else {
            games = []
            availableGames = []
            return
        }
        let all = GameRepository.allGames()
        games = all.filter { user.subscribedGames.contains($0.id) }
        availableGames = all.filter {
            $0.isPublic && !user.subscribedGames.contains($0.id)
        }
    }
    
    func subscribe(to game: Game) {
        guard let currentUser = session.currentUser() else { return }
        GameRepository.subscribe(currentUser, to: game)
        loadGames()
    }

    func deleteGames(at offsets: IndexSet) {
        guard let currentUser = session.currentUser() else { return }
        for index in offsets {
            let game = games[index]
            if game.gameOwnerUserID == currentUser.id {
                try? GameRepository.delete(game: game)
            } else {
                GameRepository.unsubscribe(currentUser, from: game)
            }
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

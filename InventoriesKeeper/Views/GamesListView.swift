//
//  GamesListView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct GamesListView: View {
    @EnvironmentObject var session: UserSession
    @State private var games: [Game] = []
    @State private var showAdd = false
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                ForEach(games, id: \.id) { game in
                    NavigationLink(value: game) {
                        Text(game.title)
                    }
                }
                .onDelete { idx in
                    idx.forEach { i in
                        try? GameRepository.delete(game: games[i])
                    }
                    if let user = session.currentUser() {
                        games = GameRepository.allGames(for: user)
                    }
                }
            }
            .navigationTitle("Your Games")
            .navigationDestination(for: Game.self) { game in
                MainMenuView(game: game, path: $navPath)
                    .environmentObject(session)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { session.logout() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+") { showAdd = true }
                }
            }
            .onAppear {
                if let user = session.currentUser() {
                    games = GameRepository.allGames(for: user)
                }
            }
            .sheet(isPresented: $showAdd) {
                if let user = session.currentUser() {
                    AddGameView(user: user, onDone: {
                        games = GameRepository.allGames(for: user)
                        showAdd = false
                    })
                } else {
                    Text("User not found")
                }
            }
        }
    }
}

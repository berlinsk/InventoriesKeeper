//
//  GamesListView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct GamesListView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var vm: GamesListViewModel

    init(session: UserSession? = nil) {
        let usedSession = session ?? UserSession()
        _vm = StateObject(wrappedValue: GamesListViewModel(session: usedSession))
    }

    var body: some View {
        NavigationStack(path: $vm.navPath) {
            List {
                ForEach(vm.games, id: \.id) { game in
                    NavigationLink(value: game) {
                        Text(game.title)
                    }
                }
                .onDelete(perform: vm.deleteGames)
            }
            .navigationTitle("Your Games")
            .navigationDestination(for: Game.self) { game in
                MainMenuView(game: game, session: session, path: $vm.navPath)
                    .environmentObject(session)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        vm.logout()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+") {
                        vm.showAdd = true
                    }
                }
            }
            .onAppear {
                vm.loadGames()
            }
            .sheet(isPresented: $vm.showAdd) {
                if let user = vm.currentUser() {
                    AddGameView(
                        vm: AddGameViewModel(user: user)
                    ) {
                        vm.loadGames()
                        vm.showAdd = false
                    }
                } else {
                    Text("User not found")
                }
            }
        }
    }
}

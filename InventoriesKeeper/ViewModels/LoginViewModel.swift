//
//  LoginViewModel.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 14.07.2025.
//

import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var errorText: String?

    private let session: UserSession

    init(session: UserSession) {
        self.session = session
    }

    func login() {
        let success = session.login(username: username, password: password)
        if !success {
            errorText = "Invalid credentials"
        }
    }

    func register() {
        let success = session.register(username: username, password: password)
        if !success {
            errorText = "User already exists"
        }
    }
}

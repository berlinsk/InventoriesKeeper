//
//  LoginView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: UserSession
    @State private var username = ""
    @State private var password = ""
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if let errorText = errorText {
                Text(errorText)
                    .foregroundColor(.red)
            }
            
            Button("Login") {
                let success = session.login(username: username, password: password)
                if !success {
                    errorText = "Invalid credentials"
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Register") {
                let success = session.register(username: username, password: password)
                if !success {
                    errorText = "User already exists"
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

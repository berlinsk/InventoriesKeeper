//
//  LoginView.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 09.07.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var viewModel: LoginViewModel

    init(session: UserSession? = nil) {
        let actualSession = session ?? UserSession()
        _viewModel = StateObject(wrappedValue: LoginViewModel(session: actualSession))
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            if let errorText = viewModel.errorText {
                Text(errorText)
                    .foregroundColor(.red)
            }

            Button("Login") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)

            Button("Register") {
                viewModel.register()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

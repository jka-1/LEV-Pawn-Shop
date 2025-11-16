//
//  LoginView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Sign In")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button("Sign In") {
                    Task {
                        do {
                            try await session.login(email: email, password: password)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(PawnTheme.gold)
                .foregroundColor(.black)
                .cornerRadius(14)
                .padding(.horizontal)

                // 👇 These will now work because RootView wraps us in NavigationStack
                NavigationLink("Forgot Password?") {
                    ForgotPasswordView()
                }
                .foregroundColor(.white)

                NavigationLink("Create New Account") {
                    RegisterView()
                }
                .foregroundColor(PawnTheme.gold)

                Spacer()
            }
            .padding(.top, 60)
        }
    }
}

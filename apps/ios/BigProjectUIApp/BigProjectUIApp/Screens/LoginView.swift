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
        NavigationStack {
            ZStack {
                PawnTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {

                    Text("Sign In")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(PawnTheme.gold)

                    // Email
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .padding(.horizontal)

                    // Password
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }

                    // Sign In Button
                    Button {
                        Task {
                            do {
                                try await session.login(email: email, password: password)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Sign In")
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(PawnTheme.gold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Forgot password
                    NavigationLink {
                        ForgotPasswordView()
                            .environmentObject(session)
                    } label: {
                        Text("Forgot Password?")
                            .foregroundStyle(.white)
                    }

                    // Create new account
                    NavigationLink {
                        RegisterView()
                            .environmentObject(session)
                    } label: {
                        Text("Create New Account")
                            .foregroundStyle(PawnTheme.gold)
                    }

                    Spacer()
                }
                .padding(.top, 60)
            }
        }
    }
}

//
//  LoginView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoggingIn: Bool = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Text("Big Lev Pawn Shop")
                        .font(.title.bold())
                        .foregroundColor(PawnTheme.gold)

                    Text("Sign In")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                // Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .pawnField()

                    SecureField("Password", text: $password)
                        .pawnField()
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign In button
                Button {
                    Task { await handleLogin() }
                } label: {
                    HStack {
                        if isLoggingIn {
                            ProgressView().tint(.black)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PawnTheme.gold)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .shadow(radius: 6)
                }
                .disabled(isLoggingIn || email.isEmpty || password.isEmpty)
                .padding(.horizontal)

                // Links
                VStack(spacing: 8) {
                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundColor(PawnTheme.gold)
                    }

                    NavigationLink {
                        RegisterView()
                    } label: {
                        Text("Create New Account")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .underline()
                    }
                }

                Spacer()
            }
        }
    }

    private func handleLogin() async {
        await MainActor.run {
            errorMessage = nil
            isLoggingIn = true
        }

        do {
            try await session.login(email: email, password: password)
            // RootView will switch to ContentView because isAuthenticated = true
        } catch {
            await MainActor.run {
                errorMessage = "Login failed. Check your email and password and try again."
                isLoggingIn = false
            }
        }
    }
}

// Reusable pawn-style field
private extension View {
    func pawnField() -> some View {
        self
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

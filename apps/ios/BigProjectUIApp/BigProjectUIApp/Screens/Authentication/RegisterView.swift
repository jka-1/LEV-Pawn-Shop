//
//  RegisterView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var errorMessage: String?
    @State private var isRegistering: Bool = false

    // 👉 Controls navigation to the 6-digit code screen
    @State private var navigateToVerifyCode: Bool = false

    // 👉 Used so EmailCodeVerificationView can tell us to pop back to Login
    @State private var shouldPopToLogin: Bool = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle.bold())
                    .foregroundColor(PawnTheme.gold)
                    .padding(.top, 20)

                VStack(spacing: 16) {
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await handleRegister() }
                } label: {
                    HStack {
                        if isRegistering {
                            ProgressView().tint(.black)
                        } else {
                            Text("Register")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? PawnTheme.gold : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .shadow(radius: 6)
                }
                .disabled(isRegistering || !canSubmit)
                .padding(.horizontal)

                Spacer()

                // Hidden NavigationLink that pushes EmailCodeVerificationView
                NavigationLink(
                    destination: EmailCodeVerificationView(
                        email: email,
                        onVerified: {
                            // 🔔 Called from EmailCodeVerificationView after tapping "Return to Login"
                            shouldPopToLogin = true
                        }
                    ),
                    isActive: $navigateToVerifyCode
                ) {
                    EmptyView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: shouldPopToLogin) { value in
            if value {
                // Pop RegisterView → back to LoginView
                dismiss()
            }
        }
    }

    private var canSubmit: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }

    private func handleRegister() async {
        await MainActor.run {
            errorMessage = nil
            isRegistering = true
        }

        do {
            // 1️⃣ Create user on backend (server sends the 6-digit code email)
            try await session.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )

            // 2️⃣ Go to code verification screen
            await MainActor.run {
                isRegistering = false
                navigateToVerifyCode = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Registration failed. Try again or use a different email."
                isRegistering = false
            }
        }
    }
}

//
//  ForgotPasswordView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email = ""
    @State private var navigate = false
    @State private var error = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Forgot Password")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)

            Button("Send Code") {
                Task {
                    let sent = await session.sendForgotPasswordCode(email: email)
                    if sent { navigate = true }
                    else { error = "Email not found" }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(PawnTheme.gold)
            .foregroundColor(.black)
            .cornerRadius(8)

            NavigationLink("Reset Password", destination:
                ResetPasswordView(email: email),
                isActive: $navigate
            )

            if !error.isEmpty {
                Text(error).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .background(PawnTheme.background.ignoresSafeArea())
    }
}

struct ResetPasswordView: View {
    let email: String
    @EnvironmentObject var session: SessionManager

    @State private var code = ""
    @State private var newPassword = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            TextField("Verification Code", text: $code)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            SecureField("New Password", text: $newPassword)
                .textFieldStyle(.roundedBorder)

            Button("Reset") {
                Task {
                    let ok = await session.resetPassword(
                        token: code,
                        newPassword: newPassword,
                        email: email
                    )
                    message = ok ? "Password Updated!" : "Invalid code"
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(PawnTheme.gold)
            .foregroundColor(.black)
            .cornerRadius(8)

            Text(message).foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(PawnTheme.background.ignoresSafeArea())
    }
}

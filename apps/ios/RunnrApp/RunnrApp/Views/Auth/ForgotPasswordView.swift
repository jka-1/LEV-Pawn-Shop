//
//  ForgotPasswordView.swift
//  RunnrApp
//
//  Created by user288801 on 11/16/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var message: String?
    @State private var isLoading = false
    private let api = StorefrontAPI.shared

    var body: some View {
        VStack(spacing: 18) {
            Text("Reset Password")
                .font(.title2.bold())

            TextField("Enter your email", text: $email)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)

            Button {
                Task {
                    isLoading = true
                    do {
                        try await api.forgotPassword(email: email)
                        message = "Reset link sent!"
                    } catch {
                        message = "Could not send reset email."
                    }
                    isLoading = false
                }
            } label: {
                Text(isLoading ? "Sending..." : "Send Reset Link")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let msg = message {
                Text(msg)
                    .foregroundColor(.yellow)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
    }
}

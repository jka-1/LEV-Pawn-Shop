//
//  ForgotPasswordView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var didSend: Bool = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.largeTitle.bold())
                    .foregroundColor(PawnTheme.gold)
                    .padding(.top, 20)

                if !didSend {
                    entryState
                } else {
                    successState
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - States

    private var entryState: some View {
        VStack(spacing: 16) {
            Text("Enter your email and we’ll send you a link to change your password.")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .pawnField()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await handleSendLink() }
            } label: {
                HStack {
                    if isSending {
                        ProgressView().tint(.black)
                    } else {
                        Text("Send Reset Link")
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
            .disabled(isSending || email.isEmpty)
        }
    }

    private var successState: some View {
        VStack(spacing: 16) {
            Text("Email Sent")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("If an account exists for \(email), a password reset link has been sent. Use that link to change your password.")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button {
                dismiss()   // back to LoginView
            } label: {
                Text("Return to Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PawnTheme.gold)
                    .foregroundColor(.black)
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Logic

    private func handleSendLink() async {
        await MainActor.run {
            errorMessage = nil
            isSending = true
        }

        let ok = await session.sendForgotPasswordCode(email: email)

        await MainActor.run {
            isSending = false
            if ok {
                didSend = true
            } else {
                errorMessage = "Something went wrong sending the reset email. Try again."
            }
        }
    }
}

// reuse pawnField again
private extension View {
    func pawnField() -> some View {
        self
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

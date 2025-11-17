//
//  EmailCodeVerificationView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//

import SwiftUI

struct EmailCodeVerificationView: View {
    let email: String
    var onVerified: (() -> Void)? = nil   // 👈 callback to RegisterView

    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var message = ""
    @State private var isVerifying = false
    @State private var isSuccess = false
    @State private var isResending = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Verify Email")
                    .font(.title.bold())
                    .foregroundColor(PawnTheme.gold)

                VStack(spacing: 6) {
                    Text("Enter the 6-digit code sent to:")
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    Text(email)
                        .foregroundColor(PawnTheme.gold)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(isSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await handleVerify() }
                } label: {
                    HStack {
                        if isVerifying {
                            ProgressView().tint(.black)
                        } else {
                            Text("Verify Code")
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
                .disabled(isVerifying || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Button {
                    Task { await handleResend() }
                } label: {
                    HStack(spacing: 8) {
                        if isResending {
                            ProgressView().tint(PawnTheme.gold)
                        }
                        Text("Resend Code")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(PawnTheme.gold)
                }
                .disabled(isResending)

                if isSuccess {
                    Button {
                        // 1️⃣ Pop this view (Email → back to Register)
                        dismiss()
                        // 2️⃣ Tell RegisterView: "hey, pop yourself back to Login"
                        onVerified?()
                    } label: {
                        Text("Return to Login")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(PawnTheme.gold)    // ✅ GOLD
                            .foregroundColor(.black)
                            .cornerRadius(14)
                            .shadow(radius: 6)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.top, 40)
        }
    }

    private func handleVerify() async {
        await MainActor.run {
            isVerifying = true
            message = ""
            isSuccess = false
        }

        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

        let ok = await session.verifyEmailCode(email: email, code: trimmed)

        await MainActor.run {
            isVerifying = false
            if ok {
                isSuccess = true
                message = "Email verified! You can now sign in."
            } else {
                isSuccess = false
                message = "Invalid or expired code. Check the code and try again, or resend."
            }
        }
    }

    private func handleResend() async {
        await MainActor.run {
            isResending = true
        }

        let ok = await session.requestVerificationCode(email: email)

        await MainActor.run {
            isResending = false
            if ok {
                message = "A new code has been sent to your email."
                isSuccess = false
            } else {
                message = "Could not resend code. Please try again later."
                isSuccess = false
            }
        }
    }
}

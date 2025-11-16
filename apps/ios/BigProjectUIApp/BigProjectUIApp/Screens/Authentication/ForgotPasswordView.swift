//
//  ForgotPasswordView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject var session: SessionManager

    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var navigateToCode: Bool = false
    @State private var isSending: Bool = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {

                Text("Reset Password")
                    .font(.largeTitle.bold())
                    .foregroundStyle(PawnTheme.gold)

                Text("Enter your email and we’ll send a 6-digit reset code.")
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .padding()
                    .background(.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)

                Button {
                    Task { await sendCode() }
                } label: {
                    if isSending {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Send Reset Code")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PawnButtonStyle())

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                NavigationLink("", isActive: $navigateToCode) {
                    EmailCodeVerificationView(email: email)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func sendCode() async {
        isSending = true
        errorMessage = nil

        let sent = await session.sendVerificationCode(to: email)

        isSending = false
        if sent {
            navigateToCode = true
        } else {
            errorMessage = "No account found with that email."
        }
    }
}

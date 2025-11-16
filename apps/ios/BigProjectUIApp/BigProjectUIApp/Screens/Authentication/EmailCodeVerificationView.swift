//
//  EmailCodeVerificationView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import SwiftUI

struct EmailCodeVerificationView: View {
    let email: String

    @EnvironmentObject var session: SessionManager
    @State private var code = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Email")
                .font(.title.bold())
                .foregroundColor(.white)

            Text("Enter the 6-digit code sent to:")
                .foregroundColor(.gray)
            Text(email).foregroundColor(PawnTheme.gold)

            TextField("Code", text: $code)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button("Verify") {
                Task {
                    let ok = await session.verifyEmailCode(email: email, code: code)
                    message = ok ? "Verified!" : "Invalid code"
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(PawnTheme.gold)
            .cornerRadius(8)
            .foregroundColor(.black)

            Text(message).foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(PawnTheme.background.ignoresSafeArea())
    }
}

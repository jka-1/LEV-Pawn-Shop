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

    @State private var code: String = ""
    @State private var statusMessage: String?
    @State private var isVerifying: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Text("Enter Verification Code")
                .font(.title).bold()

            Text("We sent a 6-digit code to \(email).")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            TextField("6-digit code", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Button {
                Task { await verify() }
            } label: {
                if isVerifying {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count != 6 || isVerifying)

            if let statusMessage {
                Text(statusMessage)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Verify Email")
    }

    private func verify() async {
        await MainActor.run {
            isVerifying = true
            statusMessage = nil
        }

        let ok = await session.verifyCode(email: email, code: code)

        await MainActor.run {
            isVerifying = false
            if ok {
                statusMessage = "Verified! You can now reset your password / log in."
                // you could dismiss() here or navigate to login
            } else {
                statusMessage = "Incorrect code. Please try again."
            }
        }
    }
}

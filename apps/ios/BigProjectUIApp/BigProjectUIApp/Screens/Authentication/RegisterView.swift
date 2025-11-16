//
//  RegisterView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: SessionManager

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var errorMessage = ""
    @State private var navigateToVerify = false

    var body: some View {
        VStack(spacing: 20) {

            Text("Create Account")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Group {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
                SecureField("Confirm Password", text: $confirmPassword)
            }
            .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await register()
                }
            } label: {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PawnTheme.gold)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }

            if navigateToVerify {
                NavigationLink("", destination:
                    EmailCodeVerificationView(email: email),
                    isActive: $navigateToVerify
                )
            }

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .background(PawnTheme.background.ignoresSafeArea())
    }

    private func register() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        do {
            try await session.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )

            let sent = await session.requestVerificationCode(email: email)
            if sent { navigateToVerify = true }

        } catch {
            errorMessage = "Email already exists or invalid"
        }
    }
}

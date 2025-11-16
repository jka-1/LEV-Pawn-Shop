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
    @State private var phone = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {

        ZStack {
            PawnTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {

                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(PawnTheme.gold)
                        .padding(.top, 30)

                    groupField("First Name", text: $firstName)
                    groupField("Last Name", text: $lastName)
                    groupField("Email", text: $email)
                    groupField("Phone Number", text: $phone)
                    secureGroupField("Password", text: $password)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }

                    Button {
                        Task {
                            do {
                                try await session.register(
                                    firstName: firstName,
                                    lastName: lastName,
                                    email: email,
                                    phone: phone,
                                    password: password
                                )
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Register")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PawnButtonStyle())

                    Spacer()
                }
                .padding()
            }
        }
    }

    private func groupField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding()
            .background(.white.opacity(0.08))
            .cornerRadius(12)
            .foregroundColor(.white)
    }

    private func secureGroupField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .padding()
            .background(.white.opacity(0.08))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

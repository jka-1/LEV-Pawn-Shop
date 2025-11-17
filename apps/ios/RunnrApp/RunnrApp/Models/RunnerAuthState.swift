//
//  RunnerAuthState.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import Foundation

@MainActor
class RunnerAuthState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var loginError: String?
    @Published var currentUser: AuthUser?

    private let api = StorefrontAPI.shared
    private let tokenKey = "RUNNER_AUTH_TOKEN"

    init() {
        autoLogin()
    }

    func login(email: String, password: String) {
        loginError = nil
        isLoading = true

        Task {
            do {
                let user = try await api.login(loginOrEmail: email, password: password)

                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isLoggedIn = true
                    self.isLoading = false

                    // Save token OR email for persistent login
                    KeychainHelper.save(key: self.tokenKey, value: user.id) // if JWT, save token instead
                    print("User logged in")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loginError = "Invalid credentials or network error."
                }
            }
        }
    }

    func autoLogin() {
        if let saved = KeychainHelper.read(key: tokenKey) {
            print("Auto-login using saved token: \(saved)")
            self.isLoggedIn = true
        }
    }

    func logout() {
        KeychainHelper.delete(key: tokenKey)
        currentUser = nil
        isLoggedIn = false
    }
}

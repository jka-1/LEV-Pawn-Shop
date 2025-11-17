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
                let response = try await api.loginRunner(email: email, password: password)
                let user = AuthUser(
                    id: response,
                    email: email,
                    username: nil,
                    login: nil,
                    firstName: nil,
                    lastName: nil
                    )

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
    
    func register(
        name: String,
        email: String,
        password: String,
        profileImage: Data?,
        certificationPDF: Data?,
        driversLicenseImage: Data?
    ) {
        loginError = nil
        isLoading = true

        Task {
            do {
                // Send registration request through StorefrontAPI
                let token = try await api.registerRunner(
                    name: name,
                    email: email,
                    password: password,
                    profileImage: profileImage,
                    certificationPDF: certificationPDF,
                    driversLicenseImage: driversLicenseImage
                )
                KeychainHelper.save(key: "token", value: token)
                
                let user = try await api.getCurrentRunner(token: token)
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isLoggedIn = true
                    self.isLoading = false
                    // Save ID/token for persistent login
                    KeychainHelper.save(key: self.tokenKey, value: user.id)
                    print("Registration successful")
                }

            } catch {
                print("Registration failed:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loginError = "Registration failed. Check your details or connection."
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

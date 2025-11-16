//
//  SessionManager.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import Foundation

@MainActor
class SessionManager: ObservableObject {
    @Published var user: AuthUser? = nil
    @Published var isAuthenticated = false

    static let shared = SessionManager()

    private init() {}

    // MARK: - Login
    func login(email: String, password: String) async throws {
        do {
            let user = try await StorefrontAPI.shared.login(
                loginOrEmail: email,
                password: password
            )
            self.user = user
            self.isAuthenticated = true
        } catch {
            throw error
        }
    }

    // MARK: - Register
    func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async throws {
        let username = email.components(separatedBy: "@").first ?? email

        let _ = try await StorefrontAPI.shared.register(
            login: username,
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
    }

    // MARK: - Request Email Verification Code
    func requestVerificationCode(email: String) async -> Bool {
        do {
            try await StorefrontAPI.shared.resendVerification(email: email)
            return true
        } catch {
            print("Verification error:", error)
            return false
        }
    }

    // MARK: - Verify Email Code
    func verifyEmailCode(email: String, code: String) async -> Bool {
        do {
            try await StorefrontAPI.shared.verifyEmailCode(email: email, code: code)
            return true
        } catch {
            print("Verify code failed:", error)
            return false
        }
    }

    // MARK: - Send Forgot Password Code
    func sendForgotPasswordCode(email: String) async -> Bool {
        do {
            try await StorefrontAPI.shared.forgotPassword(email: email)
            return true
        } catch {
            print("Forgot password error:", error)
            return false
        }
    }

    // MARK: - Reset Password
    func resetPassword(token: String, newPassword: String, email: String) async -> Bool {
        do {
            try await StorefrontAPI.shared.resetPassword(token: token, newPassword: newPassword)
            return true
        } catch {
            print("Reset failed:", error)
            return false
        }
    }

    // MARK: - Logout
    func logout() {
        self.user = nil
        self.isAuthenticated = false
    }
}

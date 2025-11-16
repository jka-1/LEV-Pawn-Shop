//
//  SessionManager.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import Foundation
import SwiftUI

// MARK: - Simple User Model
struct UserAccount: Identifiable, Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let phone: String

    init(id: UUID = UUID(),
         firstName: String,
         lastName: String,
         email: String,
         phone: String) {

        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email.lowercased()
        self.phone = phone
    }
}

// MARK: - Session Manager
@MainActor
class SessionManager: ObservableObject {

    static let shared = SessionManager()

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserAccount?

    // Fake storage (in-memory)
    private var registeredUsers: [String: UserAccount] = [:]
    private var verificationCodes: [String: String] = [:]

    private init() {}

    // MARK: - Register New User
    func register(firstName: String,
                  lastName: String,
                  email: String,
                  phone: String,
                  password: String) async throws {

        let emailLower = email.lowercased()

        if registeredUsers[emailLower] != nil {
            throw NSError(domain: "UserExists", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "An account with this email already exists."])
        }

        // Store user
        let newUser = UserAccount(firstName: firstName,
                                  lastName: lastName,
                                  email: emailLower,
                                  phone: phone)

        registeredUsers[emailLower] = newUser

        // Create verification code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        verificationCodes[emailLower] = code

        print("📩 Registration success — Verification code for \(email): \(code)")
    }

    // MARK: - Send Code for Forgot Password
    func sendVerificationCode(to email: String) async -> Bool {
        let lower = email.lowercased()

        guard registeredUsers[lower] != nil else {
            return false
        }

        let code = String(format: "%06d", Int.random(in: 0...999999))
        verificationCodes[lower] = code

        print("📩 Forgot Password — Sent code \(code) to \(email)")
        return true
    }

    // MARK: - Verify 6-Digit Code
    func verifyCode(email: String, code: String) async -> Bool {
        let lower = email.lowercased()

        guard let realCode = verificationCodes[lower] else {
            return false
        }

        if realCode == code {
            verificationCodes[lower] = nil
            print("✅ Email Verified")
            return true
        }
        return false
    }

    // MARK: - Login
    func login(email: String, password: String) async throws {
        let lower = email.lowercased()

        guard let user = registeredUsers[lower] else {
            throw NSError(domain: "LoginError", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid email or password."])
        }

        // You can add password validation later
        currentUser = user
        isLoggedIn = true
    }

    // MARK: - Logout
    func logout() {
        isLoggedIn = false
        currentUser = nil
    }
}

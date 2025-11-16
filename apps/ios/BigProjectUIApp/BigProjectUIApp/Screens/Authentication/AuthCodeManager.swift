//
//  AuthCodeManager.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/16/25.
//
import Foundation

class AuthCodeManager: ObservableObject {
    static let shared = AuthCodeManager()

    private init() {}

    @Published var lastGeneratedCode: String = ""

    func generateCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        lastGeneratedCode = code
        return code
    }

    func sendCode(to email: String, completion: @escaping (Bool) -> Void) {
        let code = generateCode()

        print("📧 Send this code to backend to email: \(email)")
        print("🔢 Code: \(code)")

        // Backend team handles sending email.
        completion(true)
    }

    func verify(code: String) -> Bool {
        return code == lastGeneratedCode
    }
}

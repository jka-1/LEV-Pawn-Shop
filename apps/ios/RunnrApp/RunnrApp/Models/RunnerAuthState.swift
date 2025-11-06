//
//  RunnerAuthState.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import Foundation

class RunnerAuthState: ObservableObject {
    @Published var isLoggedIn = false
    
    func login(email: String, password: String) {
        // Temporary fake login
        isLoggedIn = true
    }
    
    func register(name: String, email: String, password: String) {
        // Temporary fake register
        isLoggedIn = true
    }
    
    func logout() {
        isLoggedIn = false
    }
}

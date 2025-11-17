//
//  User.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

// User.swift
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String?
    // Add any additional fields returned by your API
}

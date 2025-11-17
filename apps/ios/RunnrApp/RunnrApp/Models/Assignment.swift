//
//  Assignment.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

// Assignment.swift
import Foundation

struct Assignment: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let address: String?
    let payout: Double?
    let createdAt: Date?

    // If backend uses different key casing, add CodingKeys
    enum CodingKeys: String, CodingKey {
        case id = "_id"           // or whatever your API returns
        case title
        case description
        case address
        case payout
        case createdAt
    }
}

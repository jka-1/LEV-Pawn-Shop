//
//  Item.swift
//  Apple Wallet
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import Foundation
import SwiftData

@Model
class Item: Identifiable {
    var id: UUID
    var name: String
    var price: Decimal
    var details: String
    var category: String
    var condition: String
    var imageData: Data?
    var isInCart: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        details: String = "",
        category: String = "General",
        condition: String = "Good",
        imageData: Data? = nil,
        isInCart: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.details = details
        self.category = category
        self.condition = condition
        self.imageData = imageData
        self.isInCart = isInCart
        self.createdAt = createdAt
    }
}

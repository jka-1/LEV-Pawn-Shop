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
    var condition: String
    var itemDescription: String
    var category: String
    var imageData: Data?
    var isInCart: Bool
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        condition: String = "Good",
        itemDescription: String = "",
        category: String = "General",
        imageData: Data? = nil,
        isInCart: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.condition = condition
        self.itemDescription = itemDescription
        self.category = category
        self.imageData = imageData
        self.isInCart = isInCart
        self.dateAdded = dateAdded
    }
}

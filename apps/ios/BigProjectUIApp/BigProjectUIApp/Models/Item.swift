//
//  Item.swift
//  Apple Wallet
//
//  Created by user288203 on 10/29/25.
//

import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Decimal
    var imageData: Data?
    var timestamp: Date

    init(name: String, price: Decimal, imageData: Data? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.imageData = imageData
        self.timestamp = timestamp
    }
}

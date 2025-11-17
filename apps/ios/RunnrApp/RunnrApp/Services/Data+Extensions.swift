//
//  Data+Extensions.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/17/25.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

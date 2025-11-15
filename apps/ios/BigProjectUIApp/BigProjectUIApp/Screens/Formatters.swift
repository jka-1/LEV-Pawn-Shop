//
//  Formatters.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import Foundation

let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    return f
}()

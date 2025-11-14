//
//  CheckoutScreen.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/13/25.
//
import SwiftUI

struct CheckoutScreen: View {
    var cartItems: [Item]

    @State private var paymentSuccess = false

    var totalPrice: Decimal {
        cartItems.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Checkout")
                .font(.largeTitle)
                .bold()

            List(cartItems) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text("$\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                }
            }
            .frame(height: 250)

            Text("Total: \(totalPrice as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.title2)
                .bold()

            ApplePayButton(
                total: totalPrice,
                label: "Pawn Items"
            ) { success in
                if success {
                    paymentSuccess = true
                }
            }
            .frame(width: 220, height: 50)

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $paymentSuccess) {
            ConfirmationScreen()
        }
    }
}

// Formatter
let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    return f
}()

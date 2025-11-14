//
//  ConfirmationScreen.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/13/25.
//
import SwiftUI

struct ConfirmationScreen: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("Payment Successful!")
                .font(.largeTitle).bold()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("A confirmation email has been sent.")
                .font(.title3)

            Spacer()
        }
        .padding()
        .navigationTitle("Order Complete")
    }
}


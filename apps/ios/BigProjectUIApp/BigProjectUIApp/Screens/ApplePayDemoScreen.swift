//
//  ApplePayDemo.swift
//  BigProjectUIApp
//
//  Created by user288203 on 11/14/25.
//

import SwiftUI

struct ApplePayDemoScreen: View {

    @State private var success = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Apple Pay Demo")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)

                ApplePayButton(
                    total: 20.00,
                    label: "Test Apple Pay"
                ) { result in
                    success = result
                }
                .frame(width: 220, height: 55)

                Spacer()
            }
            .padding()
        }
        .navigationDestination(isPresented: $success) {
            ConfirmationScreen()
        }
    }
}

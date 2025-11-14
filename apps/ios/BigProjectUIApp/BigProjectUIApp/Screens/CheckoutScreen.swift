import SwiftUI

struct CheckoutScreen: View {
    var cartItems: [Item]

    @State private var paymentSuccess = false

    var totalPrice: Decimal {
        cartItems.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Checkout")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)

                List(cartItems) { item in
                    HStack {
                        Text(item.name)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                            .foregroundStyle(PawnTheme.gold)
                    }
                    .listRowBackground(Color.black.opacity(0.7))
                }
                .frame(height: 250)
                .scrollContentBackground(.hidden)

                Text("Total: \(totalPrice as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.title2).bold()
                    .foregroundStyle(PawnTheme.gold)

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
        }
        .navigationDestination(isPresented: $paymentSuccess) {
            ConfirmationScreen()
        }
    }
}

let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    return f
}()

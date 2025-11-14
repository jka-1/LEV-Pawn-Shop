import SwiftUI
import SwiftData

struct CheckoutScreen: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Item> { $0.isInCart == true }) var cartItems: [Item]

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

                if cartItems.isEmpty {
                    Text("Your cart is empty.")
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    List {
                        ForEach(cartItems) { item in
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(PawnTheme.gold)

                                Button {
                                    item.isInCart = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .listRowBackground(Color.black.opacity(0.7))
                        }
                    }
                    .frame(height: 250)
                    .scrollContentBackground(.hidden)
                }

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
                .disabled(cartItems.isEmpty)

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

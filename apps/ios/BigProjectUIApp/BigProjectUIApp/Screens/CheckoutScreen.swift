import SwiftUI
import SwiftData

enum CheckoutMode: String, CaseIterable, Identifiable {
    case cart = "Cart Only"
    case all = "All Items"

    var id: String { rawValue }
}

struct CheckoutScreen: View {
    @Environment(\.modelContext) private var context
    @Query var allItems: [Item]
    @Query(filter: #Predicate<Item> { $0.isInCart == true }) var cartItems: [Item]

    @State private var mode: CheckoutMode = .cart
    @State private var paymentSuccess = false

    var itemsToPayFor: [Item] {
        mode == .cart ? cartItems : allItems
    }

    var totalPrice: Decimal {
        itemsToPayFor.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Checkout")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)

                Picker("Mode", selection: $mode) {
                    ForEach(CheckoutMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if itemsToPayFor.isEmpty {
                    Text("No items to checkout.")
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    List {
                        ForEach(itemsToPayFor) { item in
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(PawnTheme.gold)

                                if mode == .cart {
                                    Button {
                                        item.isInCart = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
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
                .disabled(itemsToPayFor.isEmpty)

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

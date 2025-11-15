import SwiftUI
import SwiftData
import PassKit

enum CheckoutMode: String, CaseIterable, Identifiable {
    case cart = "Cart Only"
    case all = "All Items"

    var id: String { rawValue }
}

struct CheckoutScreen: View {

    // MARK: SwiftData
    @Environment(\.modelContext) private var context
    @Query var allItems: [Item]
    @Query(filter: #Predicate<Item> { $0.isInCart == true }) var cartItems: [Item]

    // MARK: UI State
    @State private var mode: CheckoutMode = .cart
    @State private var paymentSuccess = false

    @State private var fullName = ""
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""

    // MARK: Derived Properties
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
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                // -------------------------------
                // Picker
                // -------------------------------
                Picker("Mode", selection: $mode) {
                    ForEach(CheckoutMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // -------------------------------
                // Items list
                // -------------------------------
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
                    .scrollContentBackground(.hidden)
                    .frame(height: 240)
                }

                // -------------------------------
                // Total Price
                // -------------------------------
                Text("Total: \(totalPrice as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.title2.bold())
                    .foregroundStyle(PawnTheme.gold)

                // -------------------------------
                // Address section
                // -------------------------------
                VStack(alignment: .leading, spacing: 12) {
                    Text("Delivery Information")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    TextField("Full Name", text: $fullName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Street Address", text: $streetAddress)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        TextField("City", text: $city)
                            .textFieldStyle(.roundedBorder)

                        TextField("State", text: $state)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }

                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // -------------------------------
                // Apple Pay Button
                // -------------------------------
                ApplePayButton(total: totalPrice, label: "Pawn Items") { success in

                    // Require address
                    guard !fullName.isEmpty,
                          !streetAddress.isEmpty,
                          !city.isEmpty,
                          !state.isEmpty,
                          !zipCode.isEmpty else {

                        print("❌ Missing address fields")
                        return
                    }

                    if success {
                        sendOrderToBackend()
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

    // ---------------------------------------------------------
    // MARK: SEND ORDER TO BACKEND
    // ---------------------------------------------------------
    func sendOrderToBackend() {
        let orderData: [String: Any] = [
            "name": fullName,
            "street": streetAddress,
            "city": city,
            "state": state,
            "zip": zipCode,
            "total": "\(totalPrice)",
            "items": itemsToPayFor.map { ["name": $0.name, "price": "\($0.price)"] }
        ]

        print("🚀 Sending order to backend:", orderData)
    }

    // ---------------------------------------------------------
    // MARK: CURRENCY FORMATTER
    // ---------------------------------------------------------
    var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }
}

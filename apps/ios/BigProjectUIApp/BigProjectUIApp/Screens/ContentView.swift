import SwiftUI
import SwiftData

struct ContentView: View {

        @Query(sort: \Item.dateAdded, order: .reverse) var items: [Item]
        @Query(filter: #Predicate<Item> { $0.isInCart == true }) var cartItems: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                PawnTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        BrandHeader()

                        Text("High-end trading that actually moves items in real life.")
                            .multilineTextAlignment(.center)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal)

                        FeaturesCard()

                        // MARK: Navigation Actions

                        // NEW: Scanner button
                        NavigationLink{
                            ScannerScreen()
                        } label: {
                            Label("Scanner", systemImage: "qrcode.viewfinder")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())
                        
                        NavigationLink {
                            AddItemView()
                        } label: {
                            Label("Add Item", systemImage: "plus.circle.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        NavigationLink {
                            InventoryView()
                        } label: {
                            Label("My Items", systemImage: "square.grid.2x2.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        NavigationLink {
                            BrowseScreen()
                        } label: {
                            Label("Browse the Shop", systemImage: "bag.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        NavigationLink {
                            MeetupScreen()
                        } label: {
                            Label("Find Meetup Location", systemImage: "map.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        NavigationLink {
                            CheckoutScreen()
                        } label: {
                            Label("Checkout", systemImage: "cart.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        NavigationLink {
                            ApplePayDemoScreen()
                        } label: {
                            Label("Apple Pay Demo", systemImage: "wallet.pass.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle(fill: PawnTheme.gold.opacity(0.7)))

                        Text("Secure flows with Apple Pay. Local runners handle pickup, validation, and delivery.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("LEV Pawn Shop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CheckoutScreen()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart.fill")
                                .font(.title3)
                                .foregroundStyle(PawnTheme.gold)

                            if cartItems.count > 0 {
                                Text("\(cartItems.count)")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.red)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
    }
}

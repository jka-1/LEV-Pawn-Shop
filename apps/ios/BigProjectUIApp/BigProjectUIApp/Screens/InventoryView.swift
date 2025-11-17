//
//  InventoryView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.dateAdded, order: .reverse) var items: [Item]

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                if items.isEmpty {
                    Spacer()
                    Text("No items in your inventory yet.")
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(items) { item in
                                NavigationLink {
                                    ItemDetailView(item: item)
                                } label: {
                                    itemCard(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("My Inventory")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal)
    }

    // MARK: - Card

    private func itemCard(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image from SwiftData
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ZstackPlaceholder(for: item)
                    .frame(height: 160)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Condition: \(item.condition)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Category: \(item.category)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.headline)
                    .foregroundStyle(PawnTheme.gold)
            }

            HStack {
                Button {
                    item.isInCart.toggle()
                } label: {
                    Label(
                        item.isInCart ? "Remove from Cart" : "Add to Cart",
                        systemImage: item.isInCart ? "cart.badge.minus" : "cart.badge.plus"
                    )
                    .foregroundStyle(.black)
                }
                .buttonStyle(PawnButtonStyle())

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.75))
                .shadow(radius: 6)
        )
    }

    // MARK: - Placeholder image

    private func ZstackPlaceholder(for item: Item) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.5))

            Text(item.name.prefix(1))
                .font(.largeTitle.bold())
                .foregroundStyle(PawnTheme.gold)
        }
    }

    // MARK: - Currency formatter

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }
}

// MARK: - Preview

struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InventoryView()
                .preferredColorScheme(.dark)
        }
    }
}

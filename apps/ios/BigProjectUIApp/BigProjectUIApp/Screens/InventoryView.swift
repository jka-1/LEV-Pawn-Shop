//
//  InventoryView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(sort: \Item.createdAt, order: .reverse) var items: [Item]

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            if items.isEmpty {
                Text("No items in your inventory yet.")
                    .foregroundStyle(.white.opacity(0.7))
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemCardView(item: item)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Items")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ItemCardView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                    Image(systemName: "photo")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(height: 120)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.footnote)
                .foregroundStyle(PawnTheme.gold)

            Button {
                item.isInCart.toggle()
            } label: {
                Label(item.isInCart ? "In Cart" : "Add to Cart",
                      systemImage: item.isInCart ? "checkmark.circle.fill" : "cart.badge.plus")
                    .font(.caption)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PawnButtonStyle(fill: item.isInCart ? PawnTheme.gold.opacity(0.6) : PawnTheme.gold))
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

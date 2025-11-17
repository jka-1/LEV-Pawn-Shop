//
//  ItemDetailView.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: Item

    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 10, y: 6)
                            .padding(.horizontal)
                    }

                    Text(item.name)
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)

                    Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.title2)
                        .foregroundStyle(PawnTheme.gold)

                    Text("Condition: \(item.condition)")
                        .foregroundStyle(.white.opacity(0.85))

                    Text("Category: \(item.category)")
                        .foregroundStyle(.white.opacity(0.85))

                    if !item.itemDescription.isEmpty {
                        Text(item.itemDescription)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal)
                    }

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

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Item", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this item?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(item)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete “\(item.name)”? This cannot be undone.")
        }
    }

    // Local currency formatter, same style as your checkout
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }
}

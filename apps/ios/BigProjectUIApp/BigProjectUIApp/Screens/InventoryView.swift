import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.dateAdded, order: .reverse) var items: [Item]

    // 3-column grid, like Browse
    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    // Fixed height for all image areas
    private let imageHeight: CGFloat = 110

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
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items) { item in
                                itemCell(item)
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

    // MARK: - Grid cell

    private func itemCell(_ item: Item) -> some View {
        VStack(spacing: 6) {

            // Tap image/card -> ItemDetailView
            NavigationLink {
                ItemDetailView(item: item)
            } label: {
                VStack(spacing: 6) {
                    // --- UNIFORM IMAGE AREA, NO VERTICAL STRETCH ---
                    Group {
                        if let data = item.imageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()        // ✅ keep aspect ratio, no stretch
                        } else {
                            ZstackPlaceholder(for: item)
                                .scaledToFit()
                        }
                    }
                    .frame(height: imageHeight)       // same height for all cells
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()                        // nothing can overflow

                    Text(item.name)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.caption2.bold())
                        .foregroundStyle(PawnTheme.gold)
                }
            }
            .buttonStyle(.plain)

            // Add / Remove from cart (same logic as before)
            Button {
                item.isInCart.toggle()
            } label: {
                Label(
                    item.isInCart ? "Remove" : "Add",
                    systemImage: item.isInCart ? "cart.badge.minus" : "cart.badge.plus"
                )
                .font(.caption)
                .foregroundStyle(.black)
            }
            .buttonStyle(PawnButtonStyle())
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.75))
                .shadow(radius: 4)
        )
    }

    // MARK: - Placeholder image

    private func ZstackPlaceholder(for item: Item) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)

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

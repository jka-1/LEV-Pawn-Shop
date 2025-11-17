//
//  BrowseScreen.swift
//  BigProjectUIApp
//
//  Remote storefront inventory from /api/storefront
//  Grid layout, infinite scroll
//

import SwiftUI
import SwiftData

// MARK: - ViewModel

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var items: [StorefrontListItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var reachedEnd: Bool = false

    private let pageSize: Int = 20
    private var nextCursor: String? = nil   // from server.nextCursor

    func loadInitial() {
        guard items.isEmpty else { return }
        Task { await loadMore() }
    }

    func loadMoreIfNeeded(currentItem item: StorefrontListItem) {
        guard let last = items.last else { return }
        if last.id == item.id {
            Task { await loadMore() }
        }
    }

    private func loadMore() async {
        guard !isLoading, !reachedEnd else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await StorefrontAPI.shared.fetchInventoryPage(
                afterId: nextCursor,
                limit: pageSize
            )

            items.append(contentsOf: response.items)
            nextCursor = response.nextCursor

            if response.nextCursor == nil {
                reachedEnd = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Delete an item from the remote storefront and update local list.
    /// Returns true on success so the caller can show a confirmation.
    func deleteItem(_ item: StorefrontListItem) async -> Bool {
        errorMessage = nil
        do {
            try await StorefrontAPI.shared.deleteItem(id: item.id)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items.remove(at: idx)
            }
            return true
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            print("❌ Delete error:", error)
            return false
        }
    }
}

// MARK: - BrowseScreen

struct BrowseScreen: View {
    @Environment(\.modelContext) private var context   // SwiftData cart Items
    @StateObject private var viewModel = BrowseViewModel()

    // 3-column grid
    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    // Alert state for successful deletion
    @State private var showDeleteSuccess = false
    @State private var deletedItemName: String = ""

    // Confirmation state BEFORE deleting
    @State private var pendingDeleteItem: StorefrontListItem? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                content
            }
        }
        .onAppear {
            viewModel.loadInitial()
        }
        // Shown AFTER a successful delete from server + local list
        .alert("Item deleted", isPresented: $showDeleteSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\"\(deletedItemName)\" was successfully deleted.")
        }
        // Confirmation BEFORE calling delete on the server
        .confirmationDialog(
            "Delete this item?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if let item = pendingDeleteItem {
                        let success = await viewModel.deleteItem(item)
                        if success {
                            deletedItemName = item.name
                            showDeleteSuccess = true
                        }
                    }
                    pendingDeleteItem = nil
                }
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteItem = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Browse Inventory")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.items.isEmpty && viewModel.isLoading {
            Spacer()
            ProgressView()
                .tint(PawnTheme.gold)
            Spacer()
        } else if viewModel.items.isEmpty {
            Spacer()
            Text("No items available yet.")
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.items) { item in
                        itemCell(item)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.vertical, 16)
                            .gridCellColumns(3)
                    } else if viewModel.reachedEnd {
                        Text("You've reached the end.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 12)
                            .gridCellColumns(3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Grid cell

    private func itemCell(_ item: StorefrontListItem) -> some View {
        VStack(spacing: 6) {

            // Tap image -> detail screen
            NavigationLink {
                StorefrontItemDetailView(item: item) {
                    addToCart(from: item)
                }
            } label: {
                storefrontImage(for: item)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text(item.name)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(String(format: "$%.2f", item.price))
                .font(.caption2.bold())
                .foregroundStyle(PawnTheme.gold)

            HStack(spacing: 8) {
                // ADD TO CART
                Button {
                    addToCart(from: item)
                } label: {
                    Image(systemName: "cart.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(PawnTheme.gold)
                .foregroundStyle(.black)
                .font(.caption)

                // DELETE (opens confirmation dialog)
                Button(role: .destructive) {
                    pendingDeleteItem = item
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.75))
        )
    }

    // MARK: - Image / placeholder

    private func storefrontImage(for item: StorefrontListItem) -> some View {
        Group {
            if let urlString = item.imageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                            ProgressView()
                                .tint(PawnTheme.gold)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage(for: item)
                    @unknown default:
                        placeholderImage(for: item)
                    }
                }
            } else {
                placeholderImage(for: item)
            }
        }
    }

    private func placeholderImage(for item: StorefrontListItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))

            Text(item.name.prefix(1))
                .font(.title.bold())
                .foregroundStyle(PawnTheme.gold)
        }
    }

    // MARK: - Bridge to your existing SwiftData cart / checkout

    private func addToCart(from storefrontItem: StorefrontListItem) {
        // Uses your Item model exactly
        let newItem = Item(
            name: storefrontItem.name,
            price: Decimal(storefrontItem.price),
            condition: "Good",
            itemDescription: storefrontItem.description ?? "",
            category: "Storefront",
            imageData: nil,
            isInCart: true
        )

        context.insert(newItem)

        do {
            try context.save()
            print("✅ Added to cart: \(storefrontItem.name)")
        } catch {
            print("❌ Failed to save cart item: \(error)")
        }
    }
}

// MARK: - Detail view for storefront items (unchanged)

struct StorefrontItemDetailView: View {
    let item: StorefrontListItem
    let onAddToCart: () -> Void

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Big image
                    if let urlString = item.imageUrl,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                    ProgressView()
                                        .tint(PawnTheme.gold)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .failure:
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        Text(item.name.prefix(1))
                                            .font(.largeTitle.bold())
                                            .foregroundColor(PawnTheme.gold)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }

                    Text(item.name)
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)

                    Text(String(format: "$%.2f", item.price))
                        .font(.title2.bold())
                        .foregroundStyle(PawnTheme.gold)

                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal)
                    }

                    Button {
                        onAddToCart()
                    } label: {
                        Label("Add to Cart", systemImage: "cart.badge.plus")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(PawnButtonStyle())
                    .padding(.top, 8)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

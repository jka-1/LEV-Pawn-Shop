//
//  BrowseScreen.swift
//  BigProjectUIApp
//
//  Remote storefront inventory from /api/storefront
//  Layout matches InventoryView style
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
}

// MARK: - BrowseScreen

struct BrowseScreen: View {
    @Environment(\.modelContext) private var context   // so we can create SwiftData cart Items
    @StateObject private var viewModel = BrowseViewModel()

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
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            StorefrontItemDetailView(item: item) {
                                addToCart(from: item)
                            }
                        } label: {
                            itemCard(item)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: item)
                        }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.vertical, 16)
                    } else if viewModel.reachedEnd {
                        Text("You've reached the end.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Card (matches InventoryView style)

    private func itemCard(_ item: StorefrontListItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Big image from server imageUrl
            if let urlString = item.imageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.4))
                            ProgressView()
                                .tint(PawnTheme.gold)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        placeholderImage(for: item)
                            .frame(height: 160)
                    @unknown default:
                        placeholderImage(for: item)
                            .frame(height: 160)
                    }
                }
            } else {
                placeholderImage(for: item)
                    .frame(height: 160)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }

                Spacer()

                Text(String(format: "$%.2f", item.price))
                    .font(.headline)
                    .foregroundStyle(PawnTheme.gold)
            }

            HStack {
                Button {
                    addToCart(from: item)
                } label: {
                    Label("Add to Cart", systemImage: "cart.badge.plus")
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

    private func placeholderImage(for item: StorefrontListItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.5))

            Text(item.name.prefix(1))
                .font(.largeTitle.bold())
                .foregroundStyle(PawnTheme.gold)
        }
    }

    // MARK: - Bridge to your existing SwiftData cart / checkout

    private func addToCart(from storefrontItem: StorefrontListItem) {
        // This creates a SwiftData Item that your CheckoutScreen already understands.
        let newItem = Item(
            name: storefrontItem.name,
            price: Decimal(storefrontItem.price),
            condition: "Good",
            itemDescription: storefrontItem.description ?? "",
            category: "Storefront",
            imageData: nil,       // you can later download and store image data if you want
            isInCart: true
        )

        context.insert(newItem)
    }
}

// MARK: - Detail view for storefront items

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

//
//  BrowseScreen.swift
//  BigProjectUIApp
//

import SwiftUI

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
    @StateObject private var viewModel = BrowseViewModel()

    var body: some View {
        ZStack {
            PawnTheme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
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
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

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
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.items) { item in
                        itemCard(item)
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
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Card UI

    @ViewBuilder
    private func itemCard(_ item: StorefrontListItem) -> some View {
        HStack(spacing: 12) {
            // Simple initial-based thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))

                Text(item.name.prefix(1))
                    .font(.title)
                    .bold()
                    .foregroundColor(PawnTheme.gold)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)

                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Text(String(format: "$%.2f", item.price))
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(PawnTheme.gold)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
                .shadow(radius: 6)
        )
    }
}

// MARK: - Preview

struct BrowseScreen_Previews: PreviewProvider {
    static var previews: some View {
        BrowseScreen()
            .preferredColorScheme(.dark)
    }
}

import SwiftUI
import UIKit
import SwiftData

struct ScannerScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var estimate: EstimatePriceResponse?
    @State private var errorMessage: String?

    // NEW: Success card toggle
    @State private var showSuccessCard = false

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {

                // MARK: - Photo Preview
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .shadow(radius: 8)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundColor(.white.opacity(0.18))

                        VStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 42))
                                .foregroundColor(PawnTheme.gold)

                            Text("Snap a photo of an item")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .padding(.horizontal)
                }

                // MARK: - Loading
                if isLoading {
                    ProgressView("Getting estimate...")
                        .tint(PawnTheme.gold)
                        .foregroundColor(.white)
                        .padding()
                }

                // MARK: - Estimate Card
                if let estimate = estimate {
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Estimated Price")
                            .foregroundStyle(.white)
                            .font(.headline)

                        Text(formattedPrice(estimate.price, currency: estimate.currency))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(PawnTheme.gold)

                        Text("Typical local listing range:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        Text(
                            "\(formattedPrice(estimate.low, currency: estimate.currency)) - \(formattedPrice(estimate.high, currency: estimate.currency))"
                        )
                        .foregroundColor(.white)

                        if !estimate.explanation.isEmpty {
                            Divider().background(.white.opacity(0.1)).padding(.vertical, 8)

                            Text("Notes")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)

                            Text(estimate.explanation)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))
                        }

                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                // MARK: - Error
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                Spacer()

                // MARK: - Snap Photo Button
                Button {
                    estimate = nil
                    errorMessage = nil
                    showingCamera = true
                } label: {
                    Label("Snap a Photo", systemImage: "camera.fill")
                        .foregroundStyle(.black)
                }
                .buttonStyle(PawnButtonStyle(fill: PawnTheme.gold))
                .padding(.horizontal)

                // MARK: - Add Item Button
                if let estimate = estimate, let image = capturedImage {
                    Button {
                        addItemToInventory(estimate: estimate, image: image)
                    } label: {
                        Label("Add Item to Inventory", systemImage: "plus.circle.fill")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(PawnButtonStyle(fill: PawnTheme.gold))
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }

            // MARK: - SUCCESS CARD OVERLAY
            if showSuccessCard {
                successCard
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera, onDismiss: handleCapturedImage) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
    }

    // MARK: - Success Card View
    private var successCard: some View {
        VStack(spacing: 20) {

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(PawnTheme.gold)

            Text("Item Added!")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Your scanned item has been successfully added to your inventory.")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                dismiss()     // Return to main screen
            } label: {
                Text("Return Home")
                    .foregroundStyle(.black)
            }
            .buttonStyle(PawnButtonStyle(fill: PawnTheme.gold))
            .padding(.horizontal)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
        .padding(40)
        .shadow(radius: 20)
    }

    // MARK: - Support Functions

    private func handleCapturedImage() {
        guard let image = capturedImage else { return }
        requestEstimate(for: image)
    }

    private func requestEstimate(for image: UIImage) {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Could not read image data."
            return
        }

        isLoading = true
        errorMessage = nil
        estimate = nil

        Task {
            do {
                let response = try await StorefrontAPI.shared.estimatePrice(
                    name: nil,
                    description: nil,
                    imageUrl: nil,
                    imageData: jpegData,
                    imageMimeType: "image/jpeg",
                    location: nil
                )

                await MainActor.run {
                    self.estimate = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to get estimate: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func addItemToInventory(estimate: EstimatePriceResponse, image: UIImage) {
        let newItem = Item(
            name: "Scanned Item",
            price: Decimal(estimate.price),
            condition: "Good",
            itemDescription: estimate.explanation,
            category: "General",
            imageData: image.jpegData(compressionQuality: 0.85),
            isInCart: false,
            dateAdded: Date()
        )

        context.insert(newItem)

        do {
            try context.save()

            // Show success card
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSuccessCard = true
            }

        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }
    }

    private func formattedPrice(_ value: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = (currency.uppercased() == "USD" ? "USD" : currency)
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}


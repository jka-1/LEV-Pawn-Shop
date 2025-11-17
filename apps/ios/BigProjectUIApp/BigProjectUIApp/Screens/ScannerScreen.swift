import SwiftUI
import UIKit

struct ScannerScreen: View {
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var estimate: EstimatePriceResponse?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Preview of snapped photo
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundColor(.gray.opacity(0.6))
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                        Text("Snap a photo of an item")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.horizontal)
            }

            // Loading indicator
            if isLoading {
                ProgressView("Getting estimate...")
                    .padding()
            }

            // Result
            if let estimate = estimate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Price")
                        .font(.headline)

                    Text(formattedPrice(estimate.price, currency: estimate.currency))
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Typical local listing range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(
                        "\(formattedPrice(estimate.low, currency: estimate.currency)) - \(formattedPrice(estimate.high, currency: estimate.currency))"
                    )
                    .font(.body)

                    if !estimate.explanation.isEmpty {
                        Divider().padding(.vertical, 8)
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(estimate.explanation)
                            .font(.footnote)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Spacer()

            // Main action button  ✅ fixed
            Button {
                // Reset state for a new scan
                estimate = nil
                errorMessage = nil
                showingCamera = true
            } label: {
                Label("Snap a Photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Scanner")
        // ✅ use your existing ImagePicker, passing sourceType
        .sheet(isPresented: $showingCamera, onDismiss: handleCapturedImage) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
    }

    // MARK: - Helpers

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

    private func formattedPrice(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        if currency.uppercased() == "USD" {
            formatter.currencyCode = "USD"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

import SwiftUI
import UIKit

// MARK: - Brand Theme

enum PawnTheme {
    static let gold = Color(red: 0.84, green: 0.70, blue: 0.28)   // Luxe "pawn shop" gold
    static let charcoal = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let slate = Color(red: 0.16, green: 0.16, blue: 0.18)

    static let background = LinearGradient(
        colors: [charcoal, slate],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PawnButtonStyle: ButtonStyle {
    var fill: Color = PawnTheme.gold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.9 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Home

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PawnTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        BrandHeader()

                        // Tagline from the linked repo’s positioning
                        // "High-end trading marketplace — that actually moves items in real life."
                        // (Readme-driven copy)
                        Text("High-end trading that actually moves items in real life.")
                            .multilineTextAlignment(.center)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal)

                        NavigationLink {
                            CameraView()
                        } label: {
                            Label("Snap Item Photos", systemImage: "camera.fill")
                                .foregroundStyle(.black) // contrast against gold
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PawnButtonStyle())

                        FeaturesCard()

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
                    Image(systemName: "crown.fill")
                        .foregroundStyle(PawnTheme.gold)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(PawnTheme.gold)
                    .symbolRenderingMode(.palette)

                Text("LEV Pawn Shop")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }

            Text("Pawn • Trade • Sell — with real-world logistics")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.top, 8)
    }
}

struct FeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What makes it different")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                FeatureRow(icon: "shippingbox.fill", title: "Real-world runners",
                           subtitle: "Pickup & drop-off, end-to-end handling.")
                FeatureRow(icon: "wand.and.stars.inverse", title: "Item validation",
                           subtitle: "Clean, verify condition before transport.")
                FeatureRow(icon: "location.circle.fill", title: "Geofenced logistics",
                           subtitle: "Smart routing & safe hand-offs.")
                FeatureRow(icon: "creditcard.fill", title: "Apple Pay",
                           subtitle: "Fast, secure checkout.")
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PawnTheme.gold.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(PawnTheme.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.footnote)
            }
            Spacer()
        }
    }
}

// MARK: - Camera

struct CameraView: View {
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                        .shadow(radius: 10, y: 6)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("No item photo yet.")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Tip: Good lighting helps our runners verify condition.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.vertical, 40)
                }

                Button {
                    isShowingCamera = true
                } label: {
                    Label(capturedImage == nil ? "Take Item Photo" : "Retake Photo", systemImage: "camera.fill")
                        .foregroundStyle(.black)
                }
                .buttonStyle(PawnButtonStyle())

                if capturedImage != nil {
                    Button {
                        capturedImage = nil
                    } label: {
                        Label("Clear Photo", systemImage: "trash")
                    }
                    .buttonStyle(PawnButtonStyle(fill: .white.opacity(0.08)))
                    .tint(.white)
                }
            }
            .padding(20)
        }
        .navigationTitle("Item Photos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(PawnTheme.gold)
                    .accessibilityLabel("Secure")
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(image: $capturedImage)
        }
    }
}

// MARK: - UIKit Camera Bridge

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Use camera when available; gracefully fall back in Simulator.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

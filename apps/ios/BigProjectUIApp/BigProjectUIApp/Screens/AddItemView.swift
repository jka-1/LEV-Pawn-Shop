import SwiftUI
import UIKit
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var priceString: String = ""
    @State private var condition: String = "Good"
    @State private var category: String = "General"
    @State private var descriptionText: String = ""
    @State private var selectedImage: UIImage?

    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera

    let conditions = ["Excellent", "Good", "Fair", "As-is"]
    let categories = ["General", "Electronics", "Jewelry", "Collectible", "Luxury"]

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Decimal(string: priceString) != nil
    }

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Add a New Item")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    TextField("Item name", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    TextField("Price ($)", text: $priceString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    Picker("Condition", selection: $condition) {
                        ForEach(conditions, id: \.self) { cond in
                            Text(cond).tag(cond)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(PawnTheme.gold)
                    .padding(.horizontal)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(PawnTheme.gold)
                    .padding(.horizontal)

                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 10, y: 6)
                            .padding(.horizontal)
                    } else {
                        Text("No photo selected yet.")
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    HStack(spacing: 12) {
                        Button {
                            imageSource = .camera
                            showImagePicker = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())

                        Button {
                            imageSource = .photoLibrary
                            showImagePicker = true
                        } label: {
                            Label("Choose Photo", systemImage: "photo.fill.on.rectangle.fill")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(PawnButtonStyle())
                    }
                    .padding(.horizontal)

                    Button {
                        saveItem()
                    } label: {
                        Label("Add to Inventory", systemImage: "tray.and.arrow.down.fill")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(PawnButtonStyle())
                    .opacity(canSave ? 1.0 : 0.4)
                    .disabled(!canSave)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSource)
        }
    }

    private func saveItem() {
        guard let price = Decimal(string: priceString) else { return }
        
        Task {
            do {
                var imageUrl = ""
                
                // If there's an image, upload it to Cloudinary first
                if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                    // Get upload signature from server
                    let signature = try await StorefrontAPI.shared.getUploadSignature()
                    
                    // Upload image to Cloudinary
                    imageUrl = try await StorefrontAPI.shared.uploadImageToCloudinary(imageData, signature: signature)
                }
                
                // Create item on server
                let serverItemId = try await StorefrontAPI.shared.createItem(
                    name: name,
                    price: NSDecimalNumber(decimal: price).doubleValue,
                    description: descriptionText.isEmpty ? nil : descriptionText,
                    imageUrl: imageUrl.isEmpty ? "https://via.placeholder.com/300x200?text=No+Image" : imageUrl,
                    tags: [condition, category],
                    active: true
                )
                
                // Also save locally for offline access
                let newItem = Item(
                    name: name,
                    price: price,
                    condition: condition,
                    itemDescription: descriptionText,
                    category: category,
                    imageData: selectedImage?.jpegData(compressionQuality: 0.8),
                    isInCart: false
                )
                
                context.insert(newItem)
                
                // Dismiss on main thread
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                print("Error uploading item: \(error)")
                // Show error to user - for now just dismiss
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}
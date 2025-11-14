import SwiftUI
import UIKit

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
                    Label(capturedImage == nil ? "Take Item Photo" : "Retake Photo",
                          systemImage: "camera.fill")
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

                Spacer()
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

// Shared UIKit bridge – keep ONE copy in project

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
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

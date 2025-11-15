import SwiftUI

struct CameraView: View {
    @State private var showSourceMenu = false
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera

    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {

                // Display Selected Image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                } else {
                    Text("No photo selected.")
                        .foregroundColor(.white.opacity(0.7))
                }

                // Choose Camera or Gallery
                Button {
                    showSourceMenu = true
                } label: {
                    Label("Take or Choose Photo", systemImage: "camera.fill")
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 220, height: 50)
                        .background(PawnTheme.gold)
                        .cornerRadius(14)
                }

                // Clear button
                if capturedImage != nil {
                    Button(role: .destructive) {
                        capturedImage = nil
                    } label: {
                        Label("Clear Photo", systemImage: "trash")
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
        }
        .actionSheet(isPresented: $showSourceMenu) {
            ActionSheet(
                title: Text("Select Photo Source"),
                buttons: [
                    .default(Text("Camera")) {
                        pickerSource = .camera
                        showPicker = true
                    },
                    .default(Text("Photo Library")) {
                        pickerSource = .photoLibrary
                        showPicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $capturedImage, sourceType: pickerSource)
        }
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .padding()
            } else {
                Text("No photo captured yet.")
                    .foregroundColor(.gray)
            }

            Button(action: {
                isShowingCamera = true
            }) {
                Text("Take Photo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $capturedImage)
            }
        }
        .navigationTitle("Camera")
    }
}

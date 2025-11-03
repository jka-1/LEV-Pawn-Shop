import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                Text("Camera App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink(destination: CameraView()) {
                    Text("Open Camera")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .navigationTitle("Welcome")
        }
    }
}

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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

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

NavigationLink(destination: MeetupScreen()) {
    Text("Find Meetup Location")
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(width: 200, height: 50)
        .background(Color.orange)
        .cornerRadius(12)
}
#endif

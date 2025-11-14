import SwiftUI

struct AddItemView: View {
    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Add a New Item")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Text("Take a picture of the item you want to pawn so runners can verify condition.")
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                NavigationLink {
                    CameraView()
                } label: {
                    Label("Open Camera", systemImage: "camera.fill")
                        .foregroundStyle(.black)
                }
                .buttonStyle(PawnButtonStyle())

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
    }
}

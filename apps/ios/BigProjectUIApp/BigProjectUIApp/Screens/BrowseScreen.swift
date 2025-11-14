import SwiftUI

struct BrowseScreen: View {
    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Browse the Shop")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Text("Store inventory UI goes here.")
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

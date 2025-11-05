import SwiftUI

struct MainScreen: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Big Lev Pawn Shop")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                NavigationLink(destination: BrowseScreen()) {
                    menuButton(label: "Browse the Shop", color: .black)
                }

                NavigationLink(destination: ContentView()) {
                    menuButton(label: "My Items", color: .yellow)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private func menuButton(label: String, color: Color) -> some View {
        Text(label)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(color)
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

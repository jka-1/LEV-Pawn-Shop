import SwiftUI

struct ConfirmationScreen: View {
    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 25) {
                Text("Payment Successful!")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("A confirmation email has been sent.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Order Complete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

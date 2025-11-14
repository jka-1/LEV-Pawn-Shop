import SwiftUI
import MapKit

struct MeetupScreen: View {
    @State private var transactionValue = ""
    @State private var suggestion: MeetupSuggestion?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.5383, longitude: -81.3792),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    let user1 = CLLocationCoordinate2D(latitude: 28.5383, longitude: -81.3792)
    let user2 = CLLocationCoordinate2D(latitude: 28.5520, longitude: -81.3798)

    var body: some View {
        ZStack {
            PawnTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Determine Meetup Location")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)

                TextField("Enter transaction value ($)", text: $transactionValue)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundStyle(.white)
                    .padding(.horizontal)

                Button {
                    guard let value = Double(transactionValue) else { return }
                    let service = MeetupService.shared
                    suggestion = service.getSuggestedLocation(user1: user1, user2: user2, transactionValue: value)
                    if let coord = suggestion?.coordinate {
                        region.center = coord
                    }
                } label: {
                    Label("Find Optimal Location", systemImage: "location.magnifyingglass")
                        .foregroundStyle(.black)
                }
                .buttonStyle(PawnButtonStyle())

                if let suggestion = suggestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested: \(suggestion.name)")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(suggestion.reason)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal)

                    Map(coordinateRegion: $region, annotationItems: [suggestion]) { item in
                        MapMarker(coordinate: item.coordinate,
                                  tint: item.type == .secure ? .red : .green)
                    }
                    .frame(height: 300)
                    .cornerRadius(16)
                    .padding()
                }

                Spacer()
            }
            .padding(.top, 16)
        }
        .navigationTitle("Meetup Finder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

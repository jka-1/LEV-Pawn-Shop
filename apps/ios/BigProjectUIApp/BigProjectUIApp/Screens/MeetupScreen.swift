import SwiftUI
import MapKit
import CoreLocation

struct MeetupScreen: View {

    @State private var userLocation: CLLocationCoordinate2D?
    @State private var transactionValue: String = ""
    @State private var suggestion: MeetupLocation?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.5383, longitude: -81.3792),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Meetup Location Finder")
                .font(.largeTitle.bold())
                .padding(.top)
            
            // MARK: Transaction Value
            TextField("Enter transaction value ($)", text: $transactionValue)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            // MARK: Find Button
            Button(action: findMeetup) {
                Text("Find Best Meetup")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            // MARK: Map View
            Map(position: .constant(.region(region))) {
                if let loc = suggestion {
                    Marker(loc.name, coordinate: loc.coordinate)
                }
                if let userLoc = userLocation {
                    Marker("You", coordinate: userLoc)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .frame(height: 350)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // MARK: Description
            if let s = suggestion {
                VStack(spacing: 8) {
                    Text("Suggested Location:")
                        .font(.headline)
                    Text(s.name)
                        .font(.title3.bold())
                    Text(s.type == .secure ? "Secure police-approved meet point" : "Standard midpoint")
                        .foregroundColor(.gray)
                }
                .padding(.top, 5)
            }
            
            Spacer()
        }
        .onAppear {
            LocationManager.shared.requestLocation()
            LocationManager.shared.locationUpdate = { coord in
                self.userLocation = coord
            }
        }
    }
    
    // MARK: Find Best Location Logic
    private func findMeetup() {
        guard let user1 = userLocation else {
            print("❌ No user location yet")
            return
        }
        
        guard let value = Double(transactionValue) else {
            print("❌ Invalid transaction value")
            return
        }
        
        let user2 = CLLocationCoordinate2D(latitude: 28.5520, longitude: -81.3798) // Example second user
        
        let result = MeetupService.shared.suggestBestMeetup(from: user1, to: user2, value: value)
        suggestion = result
        
        // Update map
        region.center = result.coordinate
    }
}

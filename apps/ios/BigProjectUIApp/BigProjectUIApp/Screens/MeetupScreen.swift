//
//  MeetupScreen.swift
//
//
//  Created by Charles Jorge on 11/3/25.
//
import SwiftUI
import MapKit

struct MeetupScreen: View {
    @State private var transactionValue = ""
    @State private var suggestion: MeetupSuggestion?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.5383, longitude: -81.3792), // default: Orlando
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let user1 = CLLocationCoordinate2D(latitude: 28.5383, longitude: -81.3792)
    let user2 = CLLocationCoordinate2D(latitude: 28.5520, longitude: -81.3798)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Determine Meetup Location")
                .font(.title)
                .bold()
            
            TextField("Enter transaction value ($)", text: $transactionValue)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button("Find Optimal Location") {
                guard let value = Double(transactionValue) else { return }
                let service = MeetupService.shared
                suggestion = service.getSuggestedLocation(user1: user1, user2: user2, transactionValue: value)
                if let coord = suggestion?.coordinate {
                    region.center = coord
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let suggestion = suggestion {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested: \(suggestion.name)")
                        .font(.headline)
                    Text(suggestion.reason)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Map(coordinateRegion: $region, annotationItems: [suggestion]) { item in
                    MapMarker(coordinate: item.coordinate,
                              tint: item.type == .secure ? .red : .green)
                }
                .frame(height: 300)
                .cornerRadius(12)
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Meetup Finder")
    }
}


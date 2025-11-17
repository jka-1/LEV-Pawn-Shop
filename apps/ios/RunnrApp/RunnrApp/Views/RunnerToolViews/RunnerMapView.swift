//
//  RunnerMapView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI
import MapKit

struct RunnerMapView: View {
    @StateObject private var locationManager = RunnerLocationManager()
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var pathCoordinates: [CLLocationCoordinate2D] = []

    // Temporary mock meetup points
    @State private var meetupPoints: [MeetupPoint] = [
        MeetupPoint(name: "Downtown Safe Exchange",
                    coordinate: CLLocationCoordinate2D(latitude: 28.601, longitude: -81.199)),
        MeetupPoint(name: "UCF Main Entrance",
                    coordinate: CLLocationCoordinate2D(latitude: 28.6025, longitude: -81.2005))
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $mapCameraPosition, interactionModes: .all) {
                // User location
                UserAnnotation()

                // Path behind runner
                if !pathCoordinates.isEmpty {
                    MapPolyline(coordinates: pathCoordinates)
                        .stroke(.blue, lineWidth: 3)
                }

                // Meetup points
                ForEach(meetupPoints) { point in
                    Annotation(point.name, coordinate: point.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.9))
                                .frame(width: 16, height: 16)
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startTracking()
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                guard let newLocation = newLocation else { return }

                // Append to path if not duplicate
                if pathCoordinates.last != newLocation {
                    pathCoordinates.append(newLocation)
                }

                // Smooth camera follow
                withAnimation(.easeInOut(duration: 0.3)) {
                    mapCameraPosition = .camera(
                        MapCamera(centerCoordinate: newLocation,
                                  distance: 300,
                                  heading: 0, pitch: 60)
                    )
                }
            }
            .ignoresSafeArea()

            // HUD overlay
            VStack(spacing: 6) {
                Text("🏃 Runner Live Mode")
                    .font(.headline)

                if let speed = locationManager.currentSpeed {
                    Text("Speed: \(String(format: "%.2f", speed)) m/s")
                }

                if let eta = locationManager.eta(to: meetupPoints.first?.coordinate) {
                    Text("ETA to \(meetupPoints.first!.name): \(eta) mins")
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 24)
        }
    }
}

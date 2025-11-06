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
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.6024, longitude: -81.2001),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    private let testDestination = CLLocationCoordinate2D(latitude: 28.6100, longitude: -81.2000)

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                // Shows system blue dot
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                guard let newLocation = newLocation else { return }
                
                let locObj = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
                                GPSAlgorithm.shared.updateLocation(locObj)
                
                position = .region(
                    MKCoordinateRegion(
                        center: newLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )

                            // Re-center camera
                            position = .region(
                                MKCoordinateRegion(
                                    center: newLocation,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            )
    }
            .ignoresSafeArea()

            Text("Runner Live Mode")
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 24)
        }
    }
}


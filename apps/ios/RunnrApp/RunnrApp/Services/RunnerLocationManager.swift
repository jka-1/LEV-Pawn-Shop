//
//  RunnerLocationManager.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class RunnerLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isAuthorized = false
    @Published var currentSpeed: Double?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5 // update every ~5 meters
    }

    // MARK: - Permissions
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Tracking
    func startTracking() {
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            startTracking()
        default:
            isAuthorized = false
            stopTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLocation = location.coordinate
        region.center = location.coordinate

        // CLLocation.speed is in m/s; negative means invalid (no movement)
        currentSpeed = location.speed >= 0 ? location.speed : 0
    }

    // MARK: - ETA Calculation
    func eta(to destination: CLLocationCoordinate2D?) -> Int? {
        guard let userLocation = userLocation, let destination = destination else { return nil }
        let user = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let dest = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distance = user.distance(from: dest) // meters
        let walkingSpeed = currentSpeed ?? 1.4 // default ~1.4 m/s
        let timeSeconds = distance / max(walkingSpeed, 0.1)
        return Int(timeSeconds / 60) // minutes
    }
    
}

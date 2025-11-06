//
//  GPSAlgorithm.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import Foundation
import CoreLocation

class GPSAlgorithm {
    static let shared = GPSAlgorithm()
    
    private var lastLocations: [CLLocation] = []
    private let maxSamples = 5  // smooth speed averaging
    
    /// Record new location updates to compute real walking speed
    func updateLocation(_ newLocation: CLLocation) {
        lastLocations.append(newLocation)
        
        if lastLocations.count > maxSamples {
            lastLocations.removeFirst()
        }
    }
    
    /// Calculate smoothed real walking speed (m/s)
    var currentSpeed: Double {
        guard lastLocations.count >= 2 else { return 0 }
        
        let first = lastLocations.first!
        let last = lastLocations.last!
        
        let distance = last.distance(from: first) // meters
        let time = last.timestamp.timeIntervalSince(first.timestamp) // seconds
        
        if time <= 0 { return 0 }
        
        return distance / time
    }
    
    /// Calculate distance to the target (meters)
    func distance(to target: CLLocationCoordinate2D, from current: CLLocationCoordinate2D) -> Double {
        let locationA = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let locationB = CLLocation(latitude: target.latitude, longitude: target.longitude)
        return locationA.distance(from: locationB)
    }
    
    /// Estimate time to destination (seconds)
    func estimatedTimeToArrival(current: CLLocationCoordinate2D, target: CLLocationCoordinate2D) -> TimeInterval {
        let distanceMeters = distance(to: target, from: current)
        let speed = max(currentSpeed, 1.3)   // 1.3 m/s = ~3 mph walking speed fallback
        
        return distanceMeters / speed
    }
    
    /// Format ETA → "14 min" or "2h 5m"
    func formatETA(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}

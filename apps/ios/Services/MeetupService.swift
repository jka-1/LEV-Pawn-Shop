//
//  MeetupService.swift
//  
//
//  Created by Charles Jorge on 11/3/25.
//

import Foundation
import CoreLocation

class MeetupService: ObservableObject {
    static let shared = MeetupService()
    
    func getSuggestedLocation(user1: CLLocationCoordinate2D,
                              user2: CLLocationCoordinate2D,
                              transactionValue: Double) -> MeetupSuggestion {
        
        // Calculate midpoint
        let midLat = (user1.latitude + user2.latitude) / 2
        let midLon = (user1.longitude + user2.longitude) / 2
        let midpoint = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
        
        // Basic logic for now
        if transactionValue >= 500 {
            return MeetupSuggestion(
                coordinate: midpoint,
                name: "Police Station (Secure)",
                address: "123 Safety Blvd",
                type: .secure,
                reason: "High-value transaction (\(transactionValue))"
            )
        } else {
            return MeetupSuggestion(
                coordinate: midpoint,
                name: "Starbucks",
                address: "456 Coffee Rd",
                type: .casual,
                reason: "Low-value transaction (\(transactionValue))"
            )
        }
    }
}

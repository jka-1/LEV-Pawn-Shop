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
    
    private let secureLocations: [LocationData]
    private let casualLocations: [LocationData]
    
    private init() {
        let data = LocationDataLoader.loadLocations()
        self.secureLocations = data.secure
        self.casualLocations = data.casual
    }
    
    func getSuggestedLocation(user1: CLLocationCoordinate2D,
                              user2: CLLocationCoordinate2D,
                              transactionValue: Double) -> MeetupSuggestion {
        
        let midLat = (user1.latitude + user2.latitude) / 2
        let midLon = (user1.longitude + user2.longitude) / 2
        
        let midpoint = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
        
        // choose list based on transaction value
        let locationPool = transactionValue >= 500 ? secureLocations : casualLocations
        
        // fallback if list empty -> midpoint
        guard let chosen = locationPool.randomElement() else {
            return MeetupSuggestion(
                coordinate: midpoint,
                name: "Midpoint",
                address: nil,
                type: transactionValue >= 500 ? .secure : .casual,
                reason: "No matching locations in Info.dict"
            )
        }
        
        return MeetupSuggestion(
            coordinate: CLLocationCoordinate2D(latitude: chosen.latitude, longitude: chosen.longitude),
            name: chosen.name,
            address: chosen.address,
            type: transactionValue >= 500 ? .secure : .casual,
            reason: "Based on transaction value: \(transactionValue)"
        )
    }
}


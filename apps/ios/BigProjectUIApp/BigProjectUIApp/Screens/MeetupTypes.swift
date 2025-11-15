//
//  MeetupTypess.swift
//  BigProjectUIApp
//
//  Created by user288203 on 11/15/25.
//
//
//  MeetupTypes.swift
//

//
//  MeetupTypes.swift
//  BigProjectUIApp
//

import Foundation
import CoreLocation

// MARK: - Location Classification
enum LocationType: String, Codable {
    case midpoint
    case secure
}

// MARK: - Reusable Location Model
struct MeetupLocation: Identifiable, Codable {
    let id: UUID = UUID()   // auto-generated, not decoded
    let name: String
    let latitude: Double
    let longitude: Double
    let type: LocationType

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // exclude `id` from Codable
    private enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, type
    }
}

// MARK: - Helper for clean creation
extension MeetupLocation {
    static func create(
        name: String,
        coordinate: CLLocationCoordinate2D,
        type: LocationType
    ) -> MeetupLocation {
        MeetupLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            type: type
        )
    }
}

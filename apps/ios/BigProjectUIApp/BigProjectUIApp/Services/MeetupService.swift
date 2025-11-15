//
//  MeetupService.swift
//

import CoreLocation
import Foundation

class MeetupService {
    static let shared = MeetupService()

    func suggestBestMeetup(from user1: CLLocationCoordinate2D,
                           to user2: CLLocationCoordinate2D,
                           value: Double) -> MeetupLocation {

        // Calculate midpoint
        let midpoint = CLLocationCoordinate2D(
            latitude: (user1.latitude + user2.latitude) / 2,
            longitude: (user1.longitude + user2.longitude) / 2
        )

        // High-value transaction → secure location
        if value >= 500 {
            return MeetupLocation.create(
                name: "Halfway Point",
                coordinate: midpoint,
                type: .midpoint
            )
        }

        // Otherwise → normal midpoint
        return MeetupLocation.create(
            name: "Secure Police Station",
            coordinate: CLLocationCoordinate2D(latitude: midpoint.latitude + 0.003,
                                               longitude: midpoint.longitude + 0.003),
            type: .secure
        )
    }
}

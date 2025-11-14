//
//  CCLLocationCoordinate2D+Equatable.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/13/25.
//

import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.000001 &&
        abs(lhs.longitude - rhs.longitude) < 0.000001
    }
}

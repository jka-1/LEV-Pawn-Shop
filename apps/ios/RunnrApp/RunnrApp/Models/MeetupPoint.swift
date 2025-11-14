//
//  MeetupPoint.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/13/25.
//

import Foundation
import CoreLocation

struct MeetupPoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

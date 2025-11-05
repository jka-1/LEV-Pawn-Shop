//
//  MeetupSuggestion.swift
//
//
//  Created by Charles Jorge on 11/3/25.
//

import Foundation
import CoreLocation

enum MeetupType {
    case secure
    case casual
}

struct MeetupSuggestion: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
    let address: String?
    let type: MeetupType
    let reason: String
}

//
//  LocationDataLoader.swift
//  BigProjectUIApp
//
//  Created by Charles Jorge on 11/5/25.
//

import Foundation
import CoreLocation

struct LocationData: Decodable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

class LocationDataLoader {
    static func loadLocations() -> (secure: [LocationData], casual: [LocationData]) {
        guard let url = Bundle.main.url(forResource: "Info", withExtension: "dict"),
              let data = try? Data(contentsOf: url) else {
            return ([], [])
        }
        
        do {
            if let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                
                let secure = parseLocations(from: plist["SecureLocations"])
                let casual = parseLocations(from: plist["CasualLocations"])
                
                return (secure, casual)
            }
        } catch {
            print("Error reading Info.dict: \(error)")
        }
        return ([], [])
    }

    private static func parseLocations(from value: Any?) -> [LocationData] {
        guard let rawArray = value as? [[String: Any]] else { return [] }
        return rawArray.compactMap { dict in
            guard let name = dict["Name"] as? String,
                  let address = dict["Address"] as? String,
                  let lat = dict["Latitude"] as? Double,
                  let lon = dict["Longitude"] as? Double else { return nil }

            return LocationData(name: name, address: address, latitude: lat, longitude: lon)
        }
    }
}

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    private let manager = CLLocationManager()

    /// Callback when GPS updates
    var locationUpdate: ((CLLocationCoordinate2D) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Ask for permission + single GPS fix
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    // MARK: - Delegate Methods

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        locationUpdate?(loc.coordinate)
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("❌ Location error:", error.localizedDescription)
    }
}

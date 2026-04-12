import CoreLocation
import Foundation
import UIKit

enum LocationPermissionHandler {
    static func statusMessage(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Location access has not been requested yet."
        case .restricted:
            return "Location is restricted on this device."
        case .denied:
            return "Location is off. Enable it in Settings to record walks."
        case .authorizedAlways:
            return "Location is allowed, including in the background."
        case .authorizedWhenInUse:
            return "Location is allowed while you use the app."
        @unknown default:
            return "Unknown location permission state."
        }
    }

    static func canOpenSettings(for status: CLAuthorizationStatus) -> Bool {
        status == .denied || status == .restricted
    }

    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

import CoreLocation
import Foundation
import SwiftUI

/// Walk tracking tuning and display constants.
enum WalkingConstants {
    /// Rough kcal scaling: distance (km) × this × 100 ≈ plausible order of magnitude for light walking estimates.
    static let defaultCalorieBurnRate: Double = 0.63

    static let locationUpdateDistance: CLLocationDistance = 10

    static let locationUpdateTimeInterval: TimeInterval = 2

    static let mapPadding: CGFloat = 50
}

import Foundation

struct AppState: Hashable, Codable {
    var isActive: Bool
    var settings: [Setting]

    var customProfiles = [Profile]()
}

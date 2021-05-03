import Foundation

struct Setting: Hashable, Codable {
    var host: String?
    var port: String?
    var profile: Profile
    var isActive: Bool
}

import Foundation

enum AuthorizationError: LocalizedError {
    case helperInstallation(String)
    case helperConnection(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .helperInstallation(let description): return "Helper installation error. \(description)"
        case .helperConnection(let description): return "Helper connection error. \(description)"
        case .unknown: return "Unknown error"
        }
    }
}

enum ExecutionError: LocalizedError {
    case invalidStringConversion
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidStringConversion: return "The output data is not convertible to a String (utf8)"
        case .unknown: return "Unknown error"
        }
    }
}

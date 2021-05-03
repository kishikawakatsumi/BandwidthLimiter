import Foundation

extension OSStatus {
    var hasSecError: Bool { self != errSecSuccess }

    var secErrorDescription: String {
        let error = SecCopyErrorMessageString(self, nil) as String? ?? "Unknown error"
        return error
    }
}

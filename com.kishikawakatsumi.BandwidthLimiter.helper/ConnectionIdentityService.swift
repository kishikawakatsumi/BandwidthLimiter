import Foundation

enum ConnectionIdentityService {
    static private let requirementString =
        #"anchor apple generic and identifier "\#(HelperConstants.bundleID)" and certificate leaf[subject.OU] = "\#(HelperConstants.subject)""# as CFString

    static func isConnectionValid(connection: NSXPCConnection) -> Bool {
        guard let token = AuditTokenHack.getAuditTokenData(from: connection) else {
            NSLog("⚠️ Unable to get the property 'auditToken' from the connection")
            return true
        }

        guard let secCode = secCodeFrom(token: token) else { return false }
        logInfoAbout(secCode: secCode)

        return verifyWithRequirementString(secCode: secCode)
    }

    private static func secCodeFrom(token: Data) -> SecCode? {
        let attributesDict = [kSecGuestAttributeAudit: token]
        var secCode: SecCode?

        let status = SecCodeCopyGuestWithAttributes(
            nil,
            attributesDict as CFDictionary,
            SecCSFlags(rawValue: 0),
            &secCode
        )

        if status.hasSecError {
            // unable to get the (running) code from the token
            NSLog("🛑 Could not get 'secCode' with the audit token. \(status.secErrorDescription)")
            return nil
        }

        return secCode
    }

    static private func verifyWithRequirementString(secCode: SecCode) -> Bool {
        var secRequirement: SecRequirement?

        let reqStatus = SecRequirementCreateWithString(requirementString, SecCSFlags(rawValue: 0), &secRequirement)
        if reqStatus.hasSecError {
            NSLog("🛑 Unable to create the requirement string. \(reqStatus.secErrorDescription)")
            return false
        }


        let validityStatus = SecCodeCheckValidity(secCode, SecCSFlags(rawValue: 0), secRequirement)
        if validityStatus.hasSecError {
            NSLog("🛑 NSXPC client does not meet the requirements. \(validityStatus.secErrorDescription)")
            return false
        }

        return true
    }

    private static func logInfoAbout(secCode: SecCode) {
        var secStaticCode: SecStaticCode?
        var cfDictionary: CFDictionary?

        SecCodeCopyStaticCode(secCode, SecCSFlags(rawValue: 0), &secStaticCode)

        guard let staticCode = secStaticCode else {
            NSLog("Unable to copy the signature of the running app")
            return
        }

        let copyStatus = SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: 0), &cfDictionary)

        if copyStatus.hasSecError {
            NSLog("⚠️ Unable to get info about connection. \(copyStatus.secErrorDescription)")
        } else if let dict = cfDictionary {
            let dict = dict as NSDictionary
            let info = dict["info-plist"] as? NSDictionary
            let bundleIdAny = info?["CFBundleIdentifier"] ?? "Unknown"
            let bundleId = String(describing: bundleIdAny)
            NSLog("Received connection request from app with bundle ID '\(bundleId)'")
        }
    }
}

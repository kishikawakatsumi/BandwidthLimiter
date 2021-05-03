import Foundation
import SecurityFoundation
import ServiceManagement

class ExecutionServiceProxy {
    private var isHelperInstalled: Bool { FileManager.default.fileExists(atPath: HelperConstants.helperPath) }

    func getProxy() throws -> HelperProtocol {
        var proxyError: Error?
        let helper = try getConnection().remoteObjectProxyWithErrorHandler { (error) in proxyError = error } as? HelperProtocol
        if let unwrappedHelper = helper {
            return unwrappedHelper
        } else {
            throw AuthorizationError.helperConnection(proxyError?.localizedDescription ?? "Unknown error")
        }
    }

    private func installHelper() throws {
        var authRef: AuthorizationRef?
        var authStatus = AuthorizationCreate(nil, nil, [.preAuthorize], &authRef)

        guard authStatus == errAuthorizationSuccess else {
            throw AuthorizationError.helperInstallation("Unable to get a valid empty authorization reference to load Helper daemon")
        }

        let authItem = kSMRightBlessPrivilegedHelper.withCString { authorizationString in
            AuthorizationItem(name: authorizationString, valueLength: 0, value: nil, flags: 0)
        }

        let pointer = UnsafeMutablePointer<AuthorizationItem>.allocate(capacity: 1)
        pointer.initialize(to: authItem)

        defer {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
        }

        var authRights = AuthorizationRights(count: 1, items: pointer)

        let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)

        guard authStatus == errAuthorizationSuccess else {
            throw AuthorizationError.helperInstallation("Unable to get a valid loading authorization reference to load Helper daemon")
        }

        var error: Unmanaged<CFError>?
        if SMJobBless(kSMDomainSystemLaunchd, HelperConstants.domain as CFString, authRef, &error) == false {
            let blessError = error!.takeRetainedValue() as Error
            throw AuthorizationError.helperInstallation("Error while installing the Helper: \(blessError.localizedDescription)")
        }

        AuthorizationFree(authRef!, [])
    }

    private func getConnection() throws -> NSXPCConnection {
        if !isHelperInstalled {
            try installHelper()
        }
        return createConnection()
    }

    private func createConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: HelperConstants.domain, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        connection.exportedObject = self

        connection.invalidationHandler = { [isHelperInstalled] in
            if isHelperInstalled {
                print("Unable to connect to Helper although it is installed")
            } else {
                print("Helper is not installed")
            }
        }

        connection.resume()
        
        return connection
    }
}

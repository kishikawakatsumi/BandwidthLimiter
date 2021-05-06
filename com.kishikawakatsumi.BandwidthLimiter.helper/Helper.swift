import Foundation

final class Helper: NSObject, NSXPCListenerDelegate, HelperProtocol {
    private let listener: NSXPCListener
    private let service = HelperExecutionService.shared

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.domain)
        super.init()
        self.listener.delegate = self
    }

    func getVersion(completion: (String) -> Void) {
        completion(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
    }

    func executeScript(at path: String, options: [String], completion: @escaping (String?, Error?) -> Void) {
        NSLog("Executing script at \(path)")
        do {
            try service.executeScript(at: path, options: options) { (result) in
                NSLog("Output: \(result.string ?? ""). Error: \(result.error?.localizedDescription ?? "")")
                completion(result.string, result.error)
            }
        } catch {
            NSLog("Error: \(error.localizedDescription)")
            completion(nil, error)
        }
    }

    func run() {
        self.listener.resume()
        RunLoop.current.run()
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        guard ConnectionIdentityService.isConnectionValid(connection: newConnection) else { return false }

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        newConnection.exportedObject = self

        newConnection.resume()

        return true
    }
}

import Foundation

final class ExecutionService {
    static let shared = ExecutionService()
    static var isHelperInstalled: Bool { FileManager().fileExists(atPath: HelperConstants.helperPath) }

    func executeScript(at path: String, options: [String], completion: @escaping (Result<String, Error>) -> Void) throws {
        let proxy = try ExecutionServiceProxy().getProxy()
        proxy.executeScript(at: path, options: options) { (output, error) in
            completion(Result(string: output, error: error))
        }
    }
}

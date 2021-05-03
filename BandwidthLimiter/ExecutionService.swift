import Foundation

final class ExecutionService {
    static let shared = ExecutionService()

    func executeScript(at path: String, options: [String], completion: @escaping (Result<String, Error>) -> Void) throws {
        let proxy = try ExecutionServiceProxy().getProxy()
        proxy.executeScript(at: path, options: options) { (output, error) in
            completion(Result(string: output, error: error))
        }
    }
}

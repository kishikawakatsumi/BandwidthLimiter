import Foundation

struct HelperExecutionService {
    static let shared = HelperExecutionService()
    static private let executableURL = URL(fileURLWithPath: "/bin/sh")

    private let queue = DispatchQueue(label: "HelperExecutionService")

    func executeScript(at path: String, options: [String], completion: @escaping (Result<String, Error>) -> Void) throws {
        let process = Process()
        process.executableURL = Self.executableURL
        process.arguments = [path] + options

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        try process.run()

        queue.async {
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

            guard let output = String(data: outputData, encoding: .utf8) else {
                completion(.failure(ExecutionError.invalidStringConversion))
                return
            }

            completion(.success(output))
        }
    }
}

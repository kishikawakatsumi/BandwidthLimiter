import Foundation

@objc(HelperProtocol)
public protocol HelperProtocol {
    func getVersion(completion: @escaping (String) -> Void)
    func executeScript(at path: String, options: [String], completion: @escaping (String?, Error?) -> Void)
}

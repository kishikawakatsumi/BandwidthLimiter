import Foundation

@objc(HelperProtocol)
public protocol HelperProtocol {
    func executeScript(at path: String, options: [String], completion: @escaping (String?, Error?) -> Void)
}

import Foundation
import Combine

final class App {
    static let shared = App()

    @Published
    var appState: AppState {
        didSet {
            try? save()
        }
    }

    var documentUrl: URL? {
        let fileManager = FileManager()
        guard let appSupportUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directoryUrl = appSupportUrl.appendingPathComponent("com.kishikawakatsumi.BandwidthLimiter")
        do {
            try fileManager.createDirectory (at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }

        return directoryUrl.appendingPathComponent("app_state.json")
    }

    init() {
        appState = AppState(isActive: false, settings: [Setting(host: nil, port: nil, profile: .default, isActive: false)])
        guard let documentUrl = documentUrl else { return }
        
        let decoder = JSONDecoder()
        if let appState = try? decoder.decode(AppState.self, from: Data(contentsOf: documentUrl)) {
            self.appState = appState
        }
    }

    private func save() throws {
        guard let documentUrl = documentUrl else { return }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appState)
        try data.write(to: documentUrl, options: .atomic)
    }
}

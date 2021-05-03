import Cocoa
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let toggleStatusMenuItem = NSMenuItem(title: "Enable Bandwidth Limiter", action: #selector(toggleLimiterStatus), keyEquivalent: "")
    private let settingsWindowController = NSStoryboard(name: "SettingsWindow", bundle: nil).instantiateInitialController() as? NSWindowController

    private var cancellables = [AnyCancellable]()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusItem(statusItem)

        let menu = NSMenu()

        menu.addItem(toggleStatusMenuItem)
        menu.addItem(NSMenuItem(title: "Configure...", action: #selector(openConfigurationWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Bandwidth Limiter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu

        App.shared.$appState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (appState) in
                guard let self = self else { return }
                self.configureStatusItem(self.statusItem)
            }
            .store(in: &cancellables)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        do {
            let tempFile = try TemporaryFile(creatingTempDirectoryForFilename: "network.sh")
            let script = TrafficShaper.generateShellScript(settings: [])
            guard let data = script.data(using: .utf8) else { return .terminateNow }
            try data.write(to: tempFile.fileURL)

            try ExecutionService.shared.executeScript(at: tempFile.fileURL.path, options: ["stop"]) { (result) in
                switch result {
                case .success(let output):
                    print(output)
                case .failure(let error):
                    print(error)
                }

                DispatchQueue.main.async {
                    sender.reply(toApplicationShouldTerminate: true)
                }
            }
        } catch {
            print(error)
            sender.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    private func configureStatusItem(_ statusItem: NSStatusItem?) {
        let isActive = App.shared.appState.isActive

        toggleStatusMenuItem.title = isActive ? "Disable Bandwidth Limiter" : "Enable Bandwidth Limiter"
        statusItem?.button?.image = isActive ? NSImage(named: "tachometer-slow-solid") : NSImage(named: "tachometer-fast-regular")
        statusItem?.button?.imagePosition = .imageLeft
    }

    @objc
    private func toggleLimiterStatus() {
        App.shared.appState.isActive.toggle()
        configureStatusItem(statusItem)
    }

    @objc
    private func openConfigurationWindow() {
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(self)
    }
}

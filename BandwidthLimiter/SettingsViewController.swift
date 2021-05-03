import AppKit
import Combine

class SettingsViewController: NSViewController {
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var statusImageView: NSImageView!
    @IBOutlet var toggleStatusButton: NSButton!

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var addRemoveButton: NSSegmentedControl!

    private var cancellables = [AnyCancellable]()

    override func viewDidLoad() {
        super.viewDidLoad()

        App.shared.$appState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (appState) in
                self?.toggleStatusButton.isEnabled = false
                self?.tableView.reloadData()

                do {
                    let tempFile = try TemporaryFile(creatingTempDirectoryForFilename: "network.sh")
                    let script = TrafficShaper.generateShellScript(settings: appState.settings)
                    print(tempFile.fileURL.path)
                    guard let data = script.data(using: .utf8) else { return }
                    try data.write(to: tempFile.fileURL)

                    try ExecutionService.shared.executeScript(at: tempFile.fileURL.path, options: [appState.isActive ? "start" : "stop"]) { [weak self] (result) in
                        switch result {
                        case .success(let output):
                            print(output)
                        case .failure(let error):
                            print(error)
                        }

                        DispatchQueue.main.async { [weak self] in
                            self?.statusLabel.objectValue = appState.isActive ? "On" : "Off"
                            self?.statusImageView.image = appState.isActive ? NSImage(named: NSImage.statusAvailableName) : NSImage(named: NSImage.statusNoneName)
                            self?.toggleStatusButton.title = "\(appState.isActive ? "Disable" : "Enable") Bandwidth Limitter"
                            self?.toggleStatusButton.isEnabled = true
                        }
                    }
                } catch {
                    print(error)
                }
            }
            .store(in: &cancellables)
    }

    @IBAction
    func addOrRemoveRow(_ sender: NSSegmentedControl) {
        var settings = App.shared.appState.settings

        switch sender.indexOfSelectedItem {
        case 0:
            settings.append(Setting(host: nil, port: nil, profile: .default, isActive: false))
        case 1:
            if tableView.selectedRow != -1 {
                settings.remove(at: tableView.selectedRow)
            }
        default:
            break
        }

        App.shared.appState.settings = settings
        tableView.reloadData()
    }
}

extension SettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let settings = App.shared.appState.settings
        return settings.count
    }
}

extension SettingsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let settings = App.shared.appState.settings

        switch tableColumn?.title {
        case "Host":
            return settings[row].host
        case "Port":
            return settings[row].port
        case "Profile":
            let index = (Profile.presets + App.shared.appState.customProfiles).firstIndex { $0.title == settings[row].profile.title }
            return index ?? 0
        case "Active":
            return settings[row].isActive
        default:
            return nil
        }
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        var settings = App.shared.appState.settings

        switch tableColumn?.title {
        case "Host":
            if let object = object {
                settings[row].host = "\(object)"
            } else {
                settings[row].host = nil
            }
        case "Port":
            if let object = object {
                settings[row].port = "\(object)"
            } else {
                settings[row].port = nil
            }
        case "Profile":
            if let index = object as? Int {
                let profiles = Profile.presets + App.shared.appState.customProfiles
                if index == -1 {
                    settings[row].profile = Profile.presets[0]
                } else if index < profiles.count {
                    settings[row].profile = profiles[index]
                } else {
                    settings[row].profile = Profile.presets[0]
                }
            }
        case "Active":
            if let object = object as? Bool {
                settings[row].isActive = object
            } else {
                settings[row].isActive = false
            }
        default:
            break
        }

        App.shared.appState.settings = settings
    }

    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if let tableColumn = tableColumn, tableColumn.identifier.rawValue == "Profile" {
            if let dataCell = tableColumn.dataCell(forRow: row) as? NSPopUpButtonCell {
                dataCell.removeAllItems()
                dataCell.addItems(withTitles: Profile.presets.map { $0.title })
                App.shared.appState.customProfiles.forEach { (profile) in
                    dataCell.addItem(withTitle: profile.title)
                }
                return dataCell
            }
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        addRemoveButton.setEnabled(tableView.selectedRow != -1, forSegment: 1)
    }

    @IBAction
    private func toggleLimiterStatus(_ sender: NSButton) {
        App.shared.appState.isActive.toggle()
    }
}

extension SettingsViewController: NSMenuDelegate {
    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        print(item.title)
        return true
    }
}

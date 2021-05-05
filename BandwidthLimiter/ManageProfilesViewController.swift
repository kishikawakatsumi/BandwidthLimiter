import AppKit
import Combine

class ManageProfilesViewController: NSViewController {
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var addRemoveButton: NSSegmentedControl!

    @IBOutlet var downBandwidthField: NSTextField!
    @IBOutlet var downBandwidthUnitButton: NSPopUpButton!
    @IBOutlet var downPacketLossRateField: NSTextField!
    @IBOutlet var downDelayField: NSTextField!

    @IBOutlet var upBandwidthField: NSTextField!
    @IBOutlet var upBandwidthUnitButton: NSPopUpButton!
    @IBOutlet var upPacketLossRateField: NSTextField!
    @IBOutlet var upDelayField: NSTextField!

    private var temporaryAppState = App.shared.appState

    private var cancellables = [AnyCancellable]()

    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.expandItem(nil, expandChildren: true)
        outlineView.selectRowIndexes([1], byExtendingSelection: false)
    }

    private func updateCurrentCustomProfile() {
        let selectedRow = outlineView.selectedRow
        guard selectedRow > Profile.presets.count + 1 else {
            return
        }

        if var item = outlineView.item(atRow: selectedRow) as? Profile {
            if downBandwidthUnitButton.indexOfSelectedItem == 0 {
                item.downBandwidth = "\(downBandwidthField.stringValue)Kbit/s"
            } else {
                item.downBandwidth = "\(downBandwidthField.stringValue)Mbit/s"
            }
            item.downPacketLossRate = String(format: "%.2f", ((Double(downPacketLossRateField.stringValue) ?? 0) * 100))
            item.downDelay = downDelayField.stringValue

            if upBandwidthUnitButton.indexOfSelectedItem == 0 {
                item.upBandwidth = "\(upBandwidthField.stringValue)Kbit/s"
            } else {
                item.upBandwidth = "\(upBandwidthField.stringValue)Mbit/s"
            }
            item.downPacketLossRate = String(format: "%.2f", ((Double(upPacketLossRateField.stringValue) ?? 0) * 100))
            item.downDelay = upDelayField.stringValue

            if selectedRow != -1 {
                temporaryAppState.customProfiles[outlineView.selectedRow - 2 - Profile.presets.count] = item

                outlineView.reloadData()
                outlineView.selectRowIndexes([selectedRow], byExtendingSelection: false)
            }
        }
    }

    @IBAction
    func addOrRemoveProfile(_ sender: NSSegmentedControl) {
        var customProfiles = temporaryAppState.customProfiles

        switch sender.indexOfSelectedItem {
        case 0:
            if let viewController = storyboard?.instantiateController(withIdentifier: "ProrileNameInput") as? NewProfileNameViewController {
                viewController.temporaryAppState = temporaryAppState
                viewController.profileAdded
                    .sink { [weak self] (appState) in
                        self?.temporaryAppState = appState
                        self?.outlineView.reloadData()
                    }
                    .store(in: &cancellables)
                
                presentAsSheet(viewController)
            }
            return
        case 1:
            if outlineView.selectedRow != -1 {
                customProfiles.remove(at: outlineView.selectedRow - 2 - Profile.presets.count)
            }
        default:
            break
        }

        temporaryAppState.customProfiles = customProfiles
        outlineView.reloadData()
    }

    @IBAction
    func editingChanged(_ sender: NSControl) {
        updateCurrentCustomProfile()
    }

    @IBAction
    func save(_ sender: NSButton) {
        updateCurrentCustomProfile()
        
        for (index, setting) in temporaryAppState.settings.enumerated() {
            let profiles = Profile.presets + temporaryAppState.customProfiles
            let profileNames = profiles.map { $0.title }
            if !profileNames.contains(setting.profile.title) {
                temporaryAppState.settings[index].profile = Profile.presets[0]
            }
        }
        App.shared.appState = temporaryAppState
        dismiss(self)
    }

    @IBAction
    func cancel(_ sender: NSButton) {
        dismiss(self)
    }
}

extension ManageProfilesViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? String, item == "Preset Profiles" {
            return Profile.presets.count
        }
        if let item = item as? String, item == "Custom Profiles" {
            return temporaryAppState.customProfiles.count
        }
        return 2
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? String, item == "Preset Profiles" {
            return Profile.presets[index]
        }
        if let item = item as? String, item == "Custom Profiles" {
            return temporaryAppState.customProfiles[index]
        }

        switch index {
        case 0:
            return "Preset Profiles"
        case 1:
            return "Custom Profiles"
        default:
            return ""
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = item as? String {
            return true
        }
        return false
    }
}

extension ManageProfilesViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("cell")
        let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as! NSTableCellView

        if let item = item as? String {
            cell.textField!.stringValue = item
            let fontDescriptor: NSFontDescriptor
            if #available(macOS 11.0, *) {
                fontDescriptor = NSFont.preferredFont(forTextStyle: .callout, options: [:]).fontDescriptor.withSymbolicTraits(.bold)
            } else {
                fontDescriptor = NSFont.boldSystemFont(ofSize: 12).fontDescriptor
            }
            cell.textField?.font = NSFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
            cell.textField?.textColor = NSColor.secondaryLabelColor
        }
        if let item = item as? Profile {
            cell.textField!.stringValue = item.title
            if #available(macOS 11.0, *) {
                cell.textField?.font = NSFont.preferredFont(forTextStyle: .body, options: [:])
            } else {
                cell.textField?.font = NSFont.systemFont(ofSize: 13)
            }
            cell.textField?.textColor = NSColor.labelColor
        }

        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if let _ = item as? String {
            return false
        }
        return true
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let item = outlineView.item(atRow: outlineView.selectedRow) as? Profile {
            if let parent = outlineView.parent(forItem: item) as? String, parent == "Preset Profiles" {
                downBandwidthField.isEnabled = false
                downBandwidthUnitButton.isEnabled = false
                downPacketLossRateField.isEnabled = false
                downDelayField.isEnabled = false

                upBandwidthField.isEnabled = false
                upBandwidthUnitButton.isEnabled = false
                upPacketLossRateField.isEnabled = false
                upDelayField.isEnabled = false

                addRemoveButton.setEnabled(false, forSegment: 1)
            } else {
                downBandwidthField.isEnabled = true
                downBandwidthUnitButton.isEnabled = true
                downPacketLossRateField.isEnabled = true
                downDelayField.isEnabled = true
                
                upBandwidthField.isEnabled = true
                upBandwidthUnitButton.isEnabled = true
                upPacketLossRateField.isEnabled = true
                upDelayField.isEnabled = true

                addRemoveButton.setEnabled(true, forSegment: 1)
            }

            if item.downBandwidth.hasSuffix("Kbit/s") {
                downBandwidthField.stringValue = item.downBandwidth.replacingOccurrences(of: "Kbit/s", with: "")
                downBandwidthUnitButton.selectItem(at: 0)
            }
            if item.downBandwidth.hasSuffix("Mbit/s") {
                downBandwidthField.stringValue = item.downBandwidth.replacingOccurrences(of: "Mbit/s", with: "")
                downBandwidthUnitButton.selectItem(at: 1)
            }
            downPacketLossRateField.stringValue = "\(Int(100 * (Double(item.downPacketLossRate) ?? 0)))"
            downDelayField.stringValue = item.downDelay

            if item.upBandwidth.hasSuffix("Kbit/s") {
                upBandwidthField.stringValue = item.upBandwidth.replacingOccurrences(of: "Kbit/s", with: "")
                upBandwidthUnitButton.selectItem(at: 0)
            }
            if item.upBandwidth.hasSuffix("Mbit/s") {
                upBandwidthField.stringValue = item.upBandwidth.replacingOccurrences(of: "Mbit/s", with: "")
                upBandwidthUnitButton.selectItem(at: 1)
            }
            upPacketLossRateField.stringValue = "\(Int(100 * (Double(item.downPacketLossRate) ?? 0)))"
            upDelayField.stringValue = item.upDelay
        }

        if outlineView.selectedRow == -1 {
            addRemoveButton.setEnabled(false, forSegment: 1)
        }
    }
}

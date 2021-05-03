import AppKit
import Combine

class NewProfileNameViewController: NSViewController {
    @IBOutlet var newProfileNameField: NSTextField!
    @IBOutlet var createButton: NSButton!

    let profileAdded = PassthroughSubject<AppState, Never>()
    var temporaryAppState: AppState?

    override func viewDidLoad() {
        super.viewDidLoad()
        createButton.keyEquivalent = "\r"
    }

    @IBAction
    func save(_ sender: NSButton) {
        guard var temporaryAppState = temporaryAppState else { return }
        var customProfiles = temporaryAppState.customProfiles

        let name = newProfileNameField.stringValue
        if (Profile.presets + customProfiles).contains(where: { $0.title == name }) {
            let alert = NSAlert()
            alert.messageText = "Profile with same name exists"
            alert.runModal()
            return
        }

        customProfiles.append(
            Profile(
                title: name,
                downBandwidth: "0Kbit/s", downPacketLossRate: "0.0", downDelay: "0",
                upBandwidth: "0Kbit/s", upPacketLossRate: "0.0", upDelay: "0"
            )
        )
        temporaryAppState.customProfiles = customProfiles
        profileAdded.send(temporaryAppState)

        dismiss(self)
    }

    @IBAction
    func cancel(_ sender: NSButton) {
        dismiss(self)
    }
}

extension NewProfileNameViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        createButton.isEnabled = !newProfileNameField.stringValue.isEmpty
    }
}

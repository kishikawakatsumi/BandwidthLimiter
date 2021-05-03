import Foundation

struct TrafficShaper {
    static func generateShellScript(settings: [Setting]) -> String {
        let profiles = Profile.presets + App.shared.appState.customProfiles

        let pipes = profiles.enumerated().map { (index, profile) in
            return
                #"""
                    sudo dnctl pipe \#((index + 1) * 2 - 1) config bw "\#(profile.downBandwidth)" plr "\#(profile.downPacketLossRate)" delay "\#(profile.downDelay)"
                    sudo dnctl pipe \#((index + 1) * 2) config bw "\#(profile.upBandwidth)" plr "\#(profile.upPacketLossRate)" delay "\#(profile.upDelay)"
                """#
        }
        .joined(separator: "\n")

        var outgoing = ""
        var incomming = ""
        for setting in settings {
            if setting.isActive {
                guard let index = profiles.firstIndex(where: { $0.title == setting.profile.title }) else { break }
                if let host = setting.host, !host.isEmpty {
                    incomming += #"dummynet in from \#(host) to any pipe \#((index + 1) * 2 - 1)\n"#
                    outgoing += #"dummynet out from any to \#(host) pipe \#((index + 1) * 2)\n"#
                } else {
                    incomming += #"dummynet in from any to any pipe \#((index + 1) * 2 - 1)\n"#
                    outgoing += #"dummynet out from any to any pipe \#((index + 1) * 2)\n"#
                }
            }
        }

        let script = """
        #!/bin/bash
        set -e

        start_stop=$1

        if [[ $start_stop == "stop" ]]; then
            echo "Resetting network conditioning..."
            sudo dnctl -q flush
            sudo pfctl -f /etc/pf.conf
            echo "done"
            exit 0
        fi

        if [[ $start_stop == "start" ]]; then
            echo "Starting network conditioning..."
            (cat /etc/pf.conf && echo "dummynet-anchor \"conditioning\"" && echo "anchor \"conditioning\"") | sudo pfctl -f -

        \(pipes)

            echo "\(incomming)\(outgoing)" | sudo pfctl -a conditioning -f -
            set +e
            sudo pfctl -e
            echo "done"
            exit 0
        fi

        echo "Need to tell us whether to 'start' or 'stop' the network conditioning"
        exit 1
        """

        return script
    }
}

import Foundation

struct Profile: Hashable, Codable {
    var title: String
    var downBandwidth: String
    var downPacketLossRate: String
    var downDelay: String
    var upBandwidth: String
    var upPacketLossRate: String
    var upDelay: String

    static let `default` = presets[1]

    static let presets = [
        Profile(
            title: "100% Loss",
            downBandwidth: "0Kbit/s", downPacketLossRate: "1.0", downDelay: "0",
            upBandwidth: "0Kbit/s", upPacketLossRate: "1.0", upDelay: "0"
        ),
        Profile(
            title: "3G",
            downBandwidth: "780Kbit/s", downPacketLossRate: "0.0", downDelay: "100",
            upBandwidth: "330Kbit/s", upPacketLossRate: "0.0", upDelay: "100"
        ),
        Profile(
            title: "DSL",
            downBandwidth: "2Mbit/s", downPacketLossRate: "0.0", downDelay: "5",
            upBandwidth: "256Kbit/s", upPacketLossRate: "0.0", upDelay: "5"
        ),
        Profile(
            title: "Edge",
            downBandwidth: "240Kbit/s", downPacketLossRate: "0.0", downDelay: "400",
            upBandwidth: "200Kbit/s", upPacketLossRate: "0.0", upDelay: "440"
        ),
        Profile(
            title: "LTE",
            downBandwidth: "50Mbit/s", downPacketLossRate: "0.0", downDelay: "50",
            upBandwidth: "10Mbit/s", upPacketLossRate: "0.0", upDelay: "65"
        ),
        Profile(
            title: "Very Bad Network",
            downBandwidth: "1Mbit/s", downPacketLossRate: "0.1", downDelay: "500",
            upBandwidth: "1Mbit/s", upPacketLossRate: "0.1", upDelay: "500"
        ),
        Profile(
            title: "Wi-Fi",
            downBandwidth: "40Mbit/s", downPacketLossRate: "0.0", downDelay: "1",
            upBandwidth: "33Mbit/s", upPacketLossRate: "0.0", upDelay: "1"
        ),
        Profile(
            title: "Wi-Fi 802.11ac",
            downBandwidth: "250Mbit/s", downPacketLossRate: "0.0", downDelay: "1",
            upBandwidth: "100Mbit/s", upPacketLossRate: "0.0", upDelay: "1"
        ),
    ]
}

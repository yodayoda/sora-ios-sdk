import Foundation
import WebRTC

private var iceTransportPolicyTable: PairTable<ICETransportPolicy, RTCIceTransportPolicy> =
    PairTable(pairs: [(.relay, .relay), (.all, .all)])

/**
 ICE 通信ポリシーを表します。
 */
public enum ICETransportPolicy {
    
    /// TURN サーバーを経由するメディアリレー候補のみを使用します。
    case relay

    /// すべての候補を使用します。
    case all
    
    var nativeValue: RTCIceTransportPolicy {
        get {
            return iceTransportPolicyTable.right(other: self)!
        }
    }
    
}

/// :nodoc:
extension ICETransportPolicy: CustomStringConvertible {

    public var description: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
    
}

/// :nodoc:
extension ICETransportPolicy: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if value == "relay" {
            self = .relay
        } else {
            throw DecodingError
                .dataCorruptedError(in: container,
                                    debugDescription: "invalid value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .relay:
            try container.encode("relay")
        case .all:
            try container.encode("all")
        }
    }
    
}

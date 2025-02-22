import Foundation
import CryptoKit
import SwiftUI

struct Transaction: Identifiable, Codable {
    let id: UUID
    let sender: String
    let recipient: String
    let amount: Double
    let timestamp: Date
    var signature: Data?

    // Deso-specific fields
    var blockHeight: Int?
    var transactionType: DesoTransactionType
    var extraData: [String: String]?
    var feeNanos: Int64

    init(sender: String, recipient: String, amount: Double, type: DesoTransactionType = .basic) {
        self.id = UUID()
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.timestamp = Date()
        self.transactionType = type
        self.feeNanos = 1000 // Default fee in nanos
    }

    func sign(with privateKey: Curve25519.Signing.PrivateKey) throws {
        let dataToSign = signableMessage()
        signature = try privateKey.signature(for: dataToSign)
    }

    func verify(with publicKey: Curve25519.Signing.PublicKey) -> Bool {
        guard let signature = signature else { return false }
        let dataToVerify = signableMessage()
        return (try? publicKey.isValidSignature(signature, for: dataToVerify)) ?? false
    }

    private func signableMessage() -> Data {
        var message = "\(sender)\(recipient)\(amount)\(timestamp.timeIntervalSince1970)"
        message += "\(transactionType.rawValue)\(feeNanos)"
        if let extraData = extraData {
            message += extraData.map { "\($0.key):\($0.value)" }.joined()
        }
        return message.data(using: .utf8)!
    }

    // Validate Deso address format
    static func isValidDesoAddress(_ address: String) -> Bool {
        // Deso addresses are base58 encoded and typically start with "BC"
        return address.count == 55 && address.hasPrefix("BC")
    }
}

enum DesoTransactionType: String, Codable {
    case basic = "BASIC"
    case follow = "FOLLOW"
    case creator = "CREATOR_COIN"
    case nft = "NFT"
    case dao = "DAO"
}
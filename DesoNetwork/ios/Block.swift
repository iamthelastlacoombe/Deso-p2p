
import Foundation
import CryptoKit

struct Block: Codable {
    let timestamp: Double
    let transactions: [Transaction]
    let previousHash: String
    let height: Int
    var nonce: Int
    var hash: String
    
    init(timestamp: Double, transactions: [Transaction], previousHash: String, height: Int) {
        self.timestamp = timestamp
        self.transactions = transactions
        self.previousHash = previousHash
        self.height = height
        self.nonce = 0
        self.hash = ""
        self.hash = calculateHash()
    }
    
    func calculateHash() -> String {
        let data = "\(timestamp)\(transactions)\(previousHash)\(height)\(nonce)".data(using: .utf8)!
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    mutating func mineBlock(difficulty: Int) {
        let prefix = String(repeating: "0", count: difficulty)
        while !hash.hasPrefix(prefix) {
            nonce += 1
            hash = calculateHash()
        }
    }
}

import Foundation
import Network
import CryptoKit

class NetworkManager: ObservableObject {
    @Published var peers: Set<NWEndpoint> = []
    @Published var isRunning = false
    @Published var recentTransactions: [CoinType: [Transaction]] = [:]
    
    func getTransactions(for coinType: CoinType) -> [Transaction] {
        return recentTransactions[coinType] ?? []
    }
    @Published var currentBlockHeight: Int = 0
    @Published var blockchain: [Block] = []
    
    private let difficulty = 4 // Number of leading zeros required for PoW
    private let blockReward = 50.0
    private var pendingTransactions: [Transaction] = []
    private let maxBlockSize = 1000 // Maximum transactions per block

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "com.deso.p2p.network")
    private let portRange = 17000...17010

    func startNode() {
        let parameters = NWParameters.tcp
        do {
            // Try each port in range until one works
            for port in portRange {
                do {
                    listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port)))
                    break
                } catch {
                    continue
                }
            }

            guard let listener = listener else {
                print("Failed to bind to any port")
                return
            }

            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        print("Node is listening on port \(listener.port?.rawValue ?? 0)")
                        self?.startDiscovery()
                    case .failed(let error):
                        print("Listener failed with error: \(error)")
                        self?.isRunning = false
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener.start(queue: queue)
        } catch {
            print("Failed to start node: \(error)")
        }
    }

    private func startDiscovery() {
        // Start local network discovery
        queue.async { [weak self] in
            self?.discoverLocalNodes()
        }

        // Schedule periodic peer list exchange
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.queue.async {
                self?.exchangePeerLists()
            }
        }
    }

    private func discoverLocalNodes() {
        guard let localIP = getLocalIP() else { return }
        let networkPrefix = localIP.split(separator: ".").dropLast().joined(separator: ".")

        for i in 1...254 {
            let targetIP = "\(networkPrefix).\(i)"
            for port in portRange {
                connectToPeer(host: targetIP, port: UInt16(port))
            }
        }
    }

    private func exchangePeerLists() {
        for endpoint in peers {
            guard case .hostPort(let host, let port) = endpoint else { continue }

            let connection = NWConnection(to: endpoint, using: .tcp)
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.sendGetPeersMessage(to: connection)
                case .failed, .cancelled:
                    self?.removeConnection(connection)
                default:
                    break
                }
            }
            connection.start(queue: queue)
        }
    }

    private func sendGetPeersMessage(to connection: NWConnection) {
        let message = DesoMessage(type: .getPeers, payload: Data())
        send(message, to: connection)
    }

    private func getLocalIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interface?.ifa_name)!)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface?.ifa_addr,
                              socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              0,
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }

    func connectToPeer(host: String, port: UInt16) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let connection = NWConnection(to: endpoint, using: .tcp)
        handleNewConnection(connection)
        connection.start(queue: queue)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receive(on: connection)
                if let endpoint = connection.endpoint {
                    DispatchQueue.main.async {
                        self?.peers.insert(endpoint)
                    }
                }
                self?.sendVersionMessage(to: connection)
            case .failed(let error):
                self?.handleNetworkError(error, context: "connection")
                self?.removeConnection(connection)
            case .cancelled:
                self?.removeConnection(connection)
            default:
                break
            }
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let error = error {
                self?.handleNetworkError(error, context: "receive")
                return
            }
            if let data = content, !data.isEmpty {
                self?.handleMessage(data, from: connection)
            }
            if !isComplete && error == nil {
                self?.receive(on: connection)
            }
        }
    }

    private func handleMessage(_ data: Data, from connection: NWConnection) {
        do {
            let message = try JSONDecoder().decode(DesoMessage.self, from: data)
            if validateDesoMessage(message) {
                switch message.type {
                case .block:
                    if let block = try? JSONDecoder().decode(Block.self, from: message.payload) {
                        handleNewBlock(block)
                    }
                case .chain:
                    if let newChain = try? JSONDecoder().decode([Block].self, from: message.payload) {
                        handleChainResponse(newChain)
                    } // Added validation
                DispatchQueue.main.async { [weak self] in
                    switch message.type {
                    case .transaction:
                        if let transaction = try? JSONDecoder().decode(Transaction.self, from: message.payload) {
                            self?.handleNewTransaction(transaction)
                        }
                    case .version:
                        if let versionInfo = try? JSONDecoder().decode(VersionInfo.self, from: message.payload) {
                            self?.handleVersionMessage(versionInfo, from: connection)
                        }
                    case .getBlocks:
                        self?.handleGetBlocksRequest(from: connection)
                    case .blocks:
                        if let blockInfo = try? JSONDecoder().decode(BlockInfo.self, from: message.payload) {
                            self?.handleBlocksResponse(blockInfo)
                        }
                    case .inv:
                        self?.handleInventory(message.payload, from: connection)
                    case .getPeers:
                        self?.handleGetPeersRequest(from: connection)
                    case .peers:
                        self?.handlePeersResponse(message.payload)
                    }
                }
            } else {
                print("Invalid Deso message received and discarded.")
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }

    private func handleNewTransaction(_ transaction: Transaction) {
        if !recentTransactions.contains(where: { $0.id == transaction.id }) {
            recentTransactions.insert(transaction, at: 0)
            broadcastTransaction(transaction)
        }
    }

    func broadcastTransaction(_ transaction: Transaction) {
        let message = DesoMessage(type: .transaction, payload: try! JSONEncoder().encode(transaction))
        broadcast(message)
    }

    private func broadcast(_ message: DesoMessage) {
        let messageData = try! JSONEncoder().encode(message)
        for connection in connections {
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Failed to broadcast message: \(error)")
                }
            })
        }
    }

    private func sendVersionMessage(to connection: NWConnection) {
        let versionInfo = VersionInfo(
            version: 2,
            services: 1,
            timestamp: Int64(Date().timeIntervalSince1970),
            height: currentBlockHeight
        )
        let message = DesoMessage(type: .version, payload: try! JSONEncoder().encode(versionInfo))
        send(message, to: connection)
    }


    private func send( _ message: DesoMessage, to connection: NWConnection) {
        let messageData = try! JSONEncoder().encode(message)
        connection.send(content: messageData, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            }
        })
    }

    private func handleVersionMessage(_ version: VersionInfo, from connection: NWConnection) {
        if version.height > currentBlockHeight {
            // Request blocks if peer has higher block height
            let getBlocks = DesoMessage(type: .getBlocks, payload: try! JSONEncoder().encode(currentBlockHeight))
            send(getBlocks, to: connection)
        }
    }

    private func handleGetBlocksRequest(from connection: NWConnection) {
        //Implement block fetching and sending logic here.  This is a placeholder.
        print("Received getblocks request")

    }

    private func handleBlocksResponse(_ blockInfo: BlockInfo) {
        //Implement block handling logic here. This is a placeholder.
        print("Received blocks response")
        currentBlockHeight = blockInfo.height
    }

    private func handleInventory(_ payload: Data, from connection: NWConnection) {
        //Implement Inventory handling here. This is a placeholder
        print("Received inventory message")
    }
    
    private func handleGetPeersRequest(from connection: NWConnection) {
        // Respond with our peer list
        let peersMessage = DesoMessage(type: .peers, payload: try! JSONEncoder().encode(Array(peers)))
        send(peersMessage, to: connection)
    }
    
    private func handlePeersResponse(_ payload: Data) {
        do {
            let receivedPeers = try JSONDecoder().decode([NWEndpoint].self, from: payload)
            for peer in receivedPeers {
                connectToPeer(host: peer.description, port: 17001) // needs adjustment
            }
        } catch {
            print("Error decoding peers response: \(error)")
        }
    }

    private func removeConnection(_ connection: NWConnection) {
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
            if let endpoint = connection.endpoint {
                DispatchQueue.main.async {
                    self.peers.remove(endpoint)
                }
            }
        }
    }
    private func handleNetworkError(_ error: Error, context: String) {
        print("Deso network error in \(context): \(error)")

        // Attempt to reconnect to bootstrap nodes if we lose all connections
        if connections.isEmpty {
            startDiscovery() // Restart discovery
        }
    }
    private func validateDesoMessage(_ message: DesoMessage) -> Bool {
        switch message.type {
        case .transaction:
            guard let transaction = try? JSONDecoder().decode(Transaction.self, from: message.payload) else {
                return false
            }
            return Transaction.isValidDesoAddress(transaction.sender) &&
                   Transaction.isValidDesoAddress(transaction.recipient)
        case .version:
            guard let version = try? JSONDecoder().decode(VersionInfo.self, from: message.payload) else {
                return false
            }
            return version.version >= 2 // Minimum supported version
        case .getPeers, .peers:
            return true
        default:
            return true
        }
    }
}

extension NetworkManager {
    private func retryConnection(to host: String, port: UInt16, attempts: Int = 3) {
        var currentAttempt = 0

        func attempt() {
            currentAttempt += 1
            connectToPeer(host: host, port: port)

            // Schedule next retry if needed
            if currentAttempt < attempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    attempt()
                }
            }
        }

        attempt()
    }
}

enum DesoMessageType: String, Codable {
    case version
    case transaction
    case getBlocks
    case blocks
    case inv
    case getPeers
    case peers
}

struct DesoMessage: Codable {
    let type: DesoMessageType
    let payload: Data
}

struct VersionInfo: Codable {
    let version: Int
    let services: Int
    let timestamp: Int64
    let height: Int
}

struct BlockInfo: Codable {
    let height: Int
    let hash: String
    let transactions: [Transaction]
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    let sender: String // Example - assuming sender address is a string
    let recipient: String // Example - assuming recipient address is a string
    // Add other relevant properties for your transaction structure

    static func isValidDesoAddress(_ address: String) -> Bool {
        // Replace with your actual Deso address validation logic
        return true // Placeholder - Replace with actual validation
    }
}

    private func validateBlock(_ block: Block) -> Bool {
        // Verify block hash
        if block.calculateHash() != block.hash {
            return false
        }
        
        // Verify proof of work
        let prefix = String(repeating: "0", count: difficulty)
        if !block.hash.hasPrefix(prefix) {
            return false
        }
        
        // Verify previous block hash
        if block.height > 0 {
            guard block.height == blockchain.count,
                  block.previousHash == blockchain.last?.hash else {
                return false
            }
        }
        
        return true
    }
    
    private func handleNewBlock(_ block: Block) {
        guard validateBlock(block) else {
            return
        }
        
        blockchain.append(block)
        currentBlockHeight = block.height
        
        // Remove processed transactions from pending
        let processedTxIds = Set(block.transactions.map { $0.id })
        pendingTransactions.removeAll { processedTxIds.contains($0.id) }
        
        // Broadcast to peers
        broadcastBlock(block)
    }
    
    private func mineBlock() {
        guard let previousBlock = blockchain.last else {
            return
        }
        
        let transactions = Array(pendingTransactions.prefix(maxBlockSize))
        var block = Block(
            timestamp: Date().timeIntervalSince1970,
            transactions: transactions,
            previousHash: previousBlock.hash,
            height: blockchain.count
        )
        
        block.mineBlock(difficulty: difficulty)
        handleNewBlock(block)
    }

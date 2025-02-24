import SwiftUI
import Network

// Add background modes and network permissions to Info.plist
/*
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Enable background networking -->
    <key>UIBackgroundModes</key>
    <array>
        <string>network-content</string>
    </array>

    <!-- Network permissions -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>DeSo P2P needs to access local network to connect with peers</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_deso._tcp</string>
    </array>
</dict>
</plist>
*/

@main
struct DeSoP2PApp: App {
    // Initialize network manager at app launch
    @StateObject private var networkManager = NetworkManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var networkManager: NetworkManager // Use environmentObject
    @State private var showingTransactionSheet = false
    @State private var showingConnectSheet = false
    @State private var connectHost = ""
    @State private var connectPort = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Network Status")) {
                    HStack {
                        Text("Active Peers")
                        Spacer()
                        Text("\(networkManager.peers.count)")
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(networkManager.isRunning ? "Running" : "Stopped")
                            .foregroundColor(networkManager.isRunning ? .green : .red)
                    }
                }

                Section(header: Text("Actions")) {
                    Button(networkManager.isRunning ? "Stop Node" : "Start Node") {
                        if networkManager.isRunning {
                            // Implement stop functionality
                        } else {
                            networkManager.startNode()
                        }
                    }

                    Button("Connect to Peer") {
                        showingConnectSheet = true
                    }

                    Button("Send Transaction") {
                        showingTransactionSheet = true
                    }
                    .disabled(!networkManager.isRunning)
                }

                Section(header: Text("Recent Transactions")) {
                    if networkManager.recentTransactions.isEmpty {
                        Text("No transactions yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(networkManager.recentTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("DeSo P2P")
            .sheet(isPresented: $showingTransactionSheet) {
                SendTransactionView(networkManager: networkManager)
            }
            .sheet(isPresented: $showingConnectSheet) {
                ConnectPeerView(networkManager: networkManager, isPresented: $showingConnectSheet)
            }
        }
    }
}

struct ConnectPeerView: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var isPresented: Bool
    @State private var host = ""
    @State private var port = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Peer Details")) {
                    TextField("Host", text: $host)
                        .autocapitalization(.none)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("Connect") {
                        if let portNumber = UInt16(port) {
                            networkManager.connectToPeer(host: host, port: portNumber)
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("Connect to Peer")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
}
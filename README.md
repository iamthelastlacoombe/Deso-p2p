# DeSo P2P Application

A Python-based P2P application for Deso coin with basic networking capabilities and iOS client.

## Project Structure

```
├── ios/
│   ├── BUILD.md
│   ├── CODEMAGIC_SETUP.md
│   ├── DeSoP2P.swift
│   ├── NetworkManager.swift
│   ├── Transaction.swift
│   └── exportOptions.plist
├── .gitignore
├── README.md
├── SSH_SETUP.md
├── cli.py
├── codemagic.yaml
├── main.py
├── network.py
├── node.py
├── transaction.py
└── utils.py
```

## Features

- P2P networking with node discovery
- Transaction creation and verification
- iOS client with SwiftUI interface
- Secure transaction signing

## Distribution

### Via Torrent

The project files are available via torrent for easy distribution. The torrent file includes all source code, documentation, and iOS client files.

Torrent Information:
- File: `deso_p2p_project.torrent`
- Size: ~38 KB
- Info Hash: 2629dd8db449d475f155206468b753f213a48df9
- Trackers:
  - udp://tracker.opentrackr.org:1337/announce
  - udp://tracker.openbittorrent.com:6969/announce

### Magnet Link

For easier sharing, you can use this magnet link:
```
magnet:?xt=urn:btih:2629dd8db449d475f155206468b753f213a48df9&dn=deso_p2p_files&xl=38594&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce
```

## Setup Instructions

1. Create a new repository on GitHub
2. Create each file in the structure shown above
3. Copy the contents of each file from the provided source
4. Install required Python packages:
   ```
   pip install cryptography
   ```

## Running the Application

```bash
python main.py
```

For iOS build instructions, see [iOS Build Guide](ios/BUILD.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
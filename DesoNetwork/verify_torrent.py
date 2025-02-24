from torf import Torrent

def verify_torrent_contents():
    """Verify the contents of the created torrent file"""
    t = Torrent.read('deso_p2p_project.torrent')
    
    print("Torrent Contents:")
    print("-" * 50)
    print(f"Name: {t.name}")
    print(f"Size: {t.size / 1024:.2f} KB")
    print(f"Files:")
    for f in t.files:
        print(f"  - {f}")
    print("-" * 50)
    print(f"Trackers: {t.trackers}")

if __name__ == "__main__":
    verify_torrent_contents()

from torf import Torrent

def generate_magnet_link():
    """Generate magnet link from the torrent file"""
    t = Torrent.read('deso_p2p_project.torrent')
    
    # Get the magnet link
    magnet_link = t.magnet()
    
    print("\nMagnet Link:")
    print("-" * 50)
    print(magnet_link)
    print("-" * 50)
    
    return magnet_link

if __name__ == "__main__":
    generate_magnet_link()

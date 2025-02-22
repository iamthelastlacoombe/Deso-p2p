import os
import shutil
from torf import Torrent

def create_project_torrent():
    """Create a torrent file for the DeSo P2P project"""
    # Create a temporary directory for the torrent contents
    temp_dir = 'deso_p2p_files'
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    # List of files to include
    files_to_include = [
        'main.py', 'cli.py', 'network.py', 'node.py', 
        'transaction.py', 'utils.py', 'README.md', 
        '.gitignore', 'SSH_SETUP.md', 'codemagic.yaml'
    ]

    # Copy files to temp directory
    for file in files_to_include:
        if os.path.exists(file):
            shutil.copy2(file, os.path.join(temp_dir, file))

    # Copy iOS folder contents
    ios_folder = 'ios'
    if os.path.exists(ios_folder):
        dest_ios_folder = os.path.join(temp_dir, 'ios')
        os.makedirs(dest_ios_folder, exist_ok=True)
        for root, _, files in os.walk(ios_folder):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, ios_folder)
                dst_path = os.path.join(dest_ios_folder, rel_path)
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)
                shutil.copy2(src_path, dst_path)

    # Create torrent
    t = Torrent(
        path=temp_dir,
        trackers=['udp://tracker.opentrackr.org:1337/announce',
                 'udp://tracker.openbittorrent.com:6969/announce'],
        comment='DeSo P2P Project Files',
        created_by='DeSo P2P Team'
    )

    # Generate torrent file
    torrent_path = 'deso_p2p_project.torrent'
    t.generate()
    t.write(torrent_path)

    print(f"Torrent file created: {torrent_path}")
    print(f"Torrent info hash: {t.infohash}")

    # Clean up temp directory
    shutil.rmtree(temp_dir)
    return torrent_path

if __name__ == "__main__":
    create_project_torrent()
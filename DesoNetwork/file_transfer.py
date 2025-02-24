import os
import zipfile
from datetime import datetime
from twilio.rest import Client

def create_project_zip():
    """Create a zip file of the project"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_filename = f"deso_p2p_{timestamp}.zip"

    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add Python files
        python_files = ['main.py', 'cli.py', 'network.py', 'node.py', 'transaction.py', 'utils.py']
        for file in python_files:
            if os.path.exists(file):
                zipf.write(file)

        # Add documentation files
        doc_files = ['README.md', '.gitignore', 'SSH_SETUP.md', 'codemagic.yaml']
        for file in doc_files:
            if os.path.exists(file):
                zipf.write(file)

        # Add iOS folder
        ios_folder = 'ios'
        if os.path.exists(ios_folder):
            for root, dirs, files in os.walk(ios_folder):
                for file in files:
                    file_path = os.path.join(root, file)
                    zipf.write(file_path)

    print(f"Project files have been zipped to: {zip_filename}")
    print(f"File size: {os.path.getsize(zip_filename) / 1024:.2f} KB")
    return zip_filename

def send_download_link(to_phone_number: str):
    """Send download link via SMS using Twilio"""
    # Make sure phone number is in E.164 format
    if not to_phone_number.startswith('+'):
        to_phone_number = '+1' + to_phone_number.replace('-', '').replace(' ', '')

    account_sid = "AC2a1cc5d79b325c5c825b9d1cdf28450d"
    auth_token = "c5ed2e46b88feb17be95abb5dd3f282b"
    twilio_phone = "+18779595215"

    client = Client(account_sid, auth_token)
    zip_file = create_project_zip()

    # Create a message with the file information
    message_body = f"""Your DeSo P2P project files are ready!
Filename: {zip_file}
Size: {os.path.getsize(zip_file) / 1024:.2f} KB
The file has been created in your Replit workspace."""

    try:
        message = client.messages.create(
            body=message_body,
            from_=twilio_phone,
            to=to_phone_number
        )
        print(f"Message sent! SID: {message.sid}")
        return True
    except Exception as e:
        print(f"Error sending message: {str(e)}")
        return False

if __name__ == "__main__":
    # Get the recipient's phone number as a command line argument
    import sys
    if len(sys.argv) != 2:
        print("Usage: python file_transfer.py <recipient_phone_number>")
        print("Example: python file_transfer.py +1234567890")
        sys.exit(1)

    recipient_number = sys.argv[1]
    send_download_link(recipient_number)
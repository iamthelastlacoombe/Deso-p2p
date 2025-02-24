import asyncio
import cmd
import json
from node import Node
from transaction import Transaction
from utils import generate_key_pair

class DesoCLI(cmd.Cmd):
    prompt = 'deso> '

    def __init__(self):
        super().__init__()
        self.node: Node | None = None
        self.private_key, self.public_key = generate_key_pair()

    def do_start(self, arg):
        """Start the node: start [port]"""
        try:
            port = int(arg) if arg else 8000
            self.node = Node(port=port)
            asyncio.create_task(self.node.start())
            print(f"Node started on port {port}")
        except ValueError:
            print("Invalid port number")

    def do_connect(self, arg):
        """Connect to a peer: connect host port"""
        try:
            if not self.node:
                print("Node not started")
                return

            host, port = arg.split()
            port = int(port)
            asyncio.create_task(self.node.connect_to_peer(host, port))
        except ValueError:
            print("Usage: connect host port")

    def do_send(self, arg):
        """Send Deso coins: send recipient amount"""
        try:
            recipient, amount = arg.split()
            amount = float(amount)

            # Create and sign transaction
            tx = Transaction(str(self.public_key), recipient, amount)
            tx.sign(self.private_key)

            # Broadcast transaction
            if self.node:
                asyncio.create_task(self.node.broadcast_transaction(tx.to_dict()))
                print(f"Transaction sent: {tx.calculate_hash()}")
            else:
                print("Node not started")
        except ValueError:
            print("Usage: send recipient amount")

    def do_peers(self, arg):
        """List connected peers"""
        if self.node:
            for peer in self.node.peers:
                print(f"{peer[0]}:{peer[1]}")
        else:
            print("Node not started")

    def do_transactions(self, arg):
        """List known transactions"""
        if self.node:
            for tx_id, tx in self.node.known_transactions.items():
                print(f"Transaction {tx_id}:")
                print(json.dumps(tx, indent=2))
        else:
            print("Node not started")

    def do_exit(self, arg):
        """Exit the application"""
        return True

def start_cli():
    cli = DesoCLI()
    try:
        cli.cmdloop()
    except KeyboardInterrupt:
        print("\nExiting...")
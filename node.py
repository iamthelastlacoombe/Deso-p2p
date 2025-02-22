import asyncio
import json
import logging
from typing import Set, Dict
from utils import generate_node_id

class Node:
    def __init__(self, host: str = '0.0.0.0', port: int = 8000):
        self.host = host
        self.port = port
        self.node_id = generate_node_id()
        self.peers: Set[tuple] = set()
        self.known_transactions: Dict[str, dict] = {}
        self.server = None

        # Setup logging with more detailed format
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    async def start(self):
        """Start the node server"""
        try:
            self.server = await asyncio.start_server(
                self.handle_connection, self.host, self.port
            )
            self.logger.info(f"Node {self.node_id} started on {self.host}:{self.port}")
            await self.server.serve_forever()
        except Exception as e:
            self.logger.error(f"Failed to start node: {str(e)}")
            raise

    async def connect_to_peer(self, host: str, port: int):
        """Connect to a new peer"""
        try:
            self.logger.info(f"Attempting to connect to peer {host}:{port}")
            reader, writer = await asyncio.open_connection(host, port)
            self.peers.add((host, port))

            # Send node info
            message = {
                'type': 'hello',
                'node_id': self.node_id,
                'host': self.host,
                'port': self.port
            }
            writer.write(json.dumps(message).encode() + b'\n')
            await writer.drain()

            self.logger.info(f"Successfully connected to peer {host}:{port}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to connect to peer {host}:{port}: {str(e)}")
            if (host, port) in self.peers:
                self.peers.remove((host, port))
            return False

    async def handle_connection(self, reader, writer):
        """Handle incoming connections"""
        peer_addr = writer.get_extra_info('peername')
        self.logger.info(f"New connection from {peer_addr}")

        while True:
            try:
                data = await reader.readline()
                if not data:
                    break

                message = json.loads(data.decode())
                self.logger.debug(f"Received message from {peer_addr}: {message['type']}")
                await self.handle_message(message, writer)

            except json.JSONDecodeError as e:
                self.logger.error(f"Invalid JSON from {peer_addr}: {str(e)}")
                break
            except Exception as e:
                self.logger.error(f"Error handling connection from {peer_addr}: {str(e)}")
                break

        writer.close()
        await writer.wait_closed()
        self.logger.info(f"Connection closed with {peer_addr}")

    async def handle_message(self, message: dict, writer):
        """Handle incoming messages"""
        try:
            if message['type'] == 'get_peers':
                response = {
                    'type': 'peers',
                    'peers': [{'host': peer[0], 'port': peer[1]} for peer in self.peers]
                }
                writer.write(json.dumps(response).encode() + b'\n')
                await writer.drain()
            elif message['type'] == 'hello':
                self.peers.add((message['host'], message['port']))
                self.logger.info(f"Added new peer: {message['host']}:{message['port']}")
                response = {
                    'type': 'hello_ack',
                    'node_id': self.node_id
                }
                writer.write(json.dumps(response).encode() + b'\n')
                await writer.drain()

            elif message['type'] == 'transaction':
                tx_id = message['transaction']['id']
                if tx_id not in self.known_transactions:
                    self.known_transactions[tx_id] = message['transaction']
                    self.logger.info(f"Received new transaction: {tx_id}")
                    await self.broadcast_transaction(message['transaction'])
        except Exception as e:
            self.logger.error(f"Error handling message: {str(e)}")

    async def broadcast_transaction(self, transaction: dict):
        """Broadcast transaction to all peers"""
        message = {
            'type': 'transaction',
            'transaction': transaction
        }

        for peer in self.peers.copy():  # Use copy to avoid modification during iteration
            try:
                self.logger.debug(f"Broadcasting transaction to peer {peer}")
                reader, writer = await asyncio.open_connection(peer[0], peer[1])
                writer.write(json.dumps(message).encode() + b'\n')
                await writer.drain()
                writer.close()
                await writer.wait_closed()
            except Exception as e:
                self.logger.error(f"Failed to broadcast to {peer}: {str(e)}")
                self.peers.remove(peer)  # Remove unreachable peer
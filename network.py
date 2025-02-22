
import asyncio
import json
import socket
import logging
from typing import Set
import random

class NetworkManager:
    def __init__(self):
        self.known_nodes: Set[tuple] = set()
        self.logger = logging.getLogger(__name__)
        self.port_range = (17000, 17010)  # Range of ports to scan

    async def start_discovery(self):
        """Start pure P2P node discovery"""
        while True:
            try:
                # Local network discovery
                await self.discover_local_nodes()
                # Ask known peers for their peers
                await self.exchange_peer_lists()
                await asyncio.sleep(300)  # Every 5 minutes
            except Exception as e:
                self.logger.error(f"Discovery error: {str(e)}")

    async def discover_local_nodes(self):
        """Discover nodes on local network"""
        local_ip = self.get_local_ip()
        network_prefix = '.'.join(local_ip.split('.')[:-1])
        
        for i in range(1, 255):
            target_ip = f"{network_prefix}.{i}"
            for port in range(self.port_range[0], self.port_range[1]):
                try:
                    reader, writer = await asyncio.open_connection(target_ip, port)
                    self.known_nodes.add((target_ip, port))
                    writer.close()
                    await writer.wait_closed()
                except:
                    continue

    async def exchange_peer_lists(self):
        """Exchange peer lists with known peers"""
        for peer in self.known_nodes.copy():
            try:
                reader, writer = await asyncio.open_connection(peer[0], peer[1])
                message = {
                    'type': 'get_peers'
                }
                writer.write(json.dumps(message).encode() + b'\n')
                await writer.drain()

                data = await reader.readline()
                if data:
                    response = json.loads(data.decode())
                    if response['type'] == 'peers':
                        for peer_info in response['peers']:
                            self.known_nodes.add((peer_info['host'], peer_info['port']))

                writer.close()
                await writer.wait_closed()
            except Exception:
                self.known_nodes.remove(peer)

    def get_local_ip(self):
        """Get local IP address"""
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('8.8.8.8', 80))
            ip = s.getsockname()[0]
        except:
            ip = '127.0.0.1'
        finally:
            s.close()
        return ip

    async def maintain_network(self):
        """Maintain network connections"""
        while True:
            dead_nodes = set()
            for node in self.known_nodes:
                if not await self.ping_node(node[0], node[1]):
                    dead_nodes.add(node)
            self.known_nodes -= dead_nodes
            await asyncio.sleep(60)

    async def ping_node(self, host: str, port: int) -> bool:
        """Ping a node to check if it's alive"""
        try:
            reader, writer = await asyncio.open_connection(host, port)
            message = {'type': 'ping'}
            writer.write(json.dumps(message).encode() + b'\n')
            await writer.drain()
            data = await reader.readline()
            writer.close()
            await writer.wait_closed()
            return data and json.loads(data.decode()).get('type') == 'pong'
        except:
            return False

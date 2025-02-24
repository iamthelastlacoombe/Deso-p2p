import hashlib
import time
import json
from typing import Dict, Optional
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding, rsa

class Transaction:
    def __init__(self, sender: str, recipient: str, amount: float):
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.timestamp = int(time.time())
        self.signature = None

    def to_dict(self) -> Dict:
        """Convert transaction to dictionary"""
        return {
            'sender': self.sender,
            'recipient': self.recipient,
            'amount': self.amount,
            'timestamp': self.timestamp,
            'signature': self.signature
        }

    def calculate_hash(self) -> str:
        """Calculate transaction hash"""
        tx_string = f"{self.sender}{self.recipient}{self.amount}{self.timestamp}"
        return hashlib.sha256(tx_string.encode()).hexdigest()

    def sign(self, private_key: rsa.RSAPrivateKey):
        """Sign the transaction"""
        tx_hash = self.calculate_hash()
        signature = private_key.sign(
            tx_hash.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        self.signature = base64.b64encode(signature).decode()

    def verify(self, public_key: rsa.RSAPublicKey) -> bool:
        """Verify transaction signature"""
        if not self.signature:
            return False

        try:
            signature = base64.b64decode(self.signature)
            tx_hash = self.calculate_hash()

            public_key.verify(
                signature,
                tx_hash.encode(),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False

class TransactionPool:
    def __init__(self):
        self.transactions: Dict[str, Transaction] = {}

    def add_transaction(self, transaction: Transaction) -> bool:
        """Add a transaction to the pool"""
        tx_hash = transaction.calculate_hash()
        if tx_hash not in self.transactions:
            self.transactions[tx_hash] = transaction
            return True
        return False

    def get_transaction(self, tx_hash: str) -> Optional[Transaction]:
        """Get a transaction from the pool"""
        return self.transactions.get(tx_hash)

    def remove_transaction(self, tx_hash: str):
        """Remove a transaction from the pool"""
        if tx_hash in self.transactions:
            del self.transactions[tx_hash]
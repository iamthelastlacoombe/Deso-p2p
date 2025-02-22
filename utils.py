import uuid
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

def generate_node_id() -> str:
    """Generate a unique node ID"""
    return str(uuid.uuid4())

def generate_key_pair():
    """Generate RSA key pair"""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    public_key = private_key.public_key()

    return private_key, public_key

def serialize_public_key(public_key) -> str:
    """Serialize public key to string"""
    return public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
        backend=default_backend()
    ).decode()

def deserialize_public_key(key_str: str):
    """Deserialize public key from string"""
    return serialization.load_pem_public_key(
        key_str.encode(),
        backend=default_backend()
    )
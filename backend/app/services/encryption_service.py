"""Encryption service for AES-256 data protection."""
import base64
import hashlib
import os


class EncryptionService:
    """Encrypts and decrypts strings using AES-256-compatible XOR cipher.

    Note: This is a simplified implementation for demonstration.
    Production should use the cryptography library with Fernet or AES-GCM.
    """

    def __init__(self, secret_key: str = "default-secret-key-for-testing"):
        self._key = hashlib.sha256(secret_key.encode()).digest()

    def encrypt(self, plaintext: str) -> str:
        """Encrypt a plaintext string, returning base64-encoded ciphertext."""
        if not plaintext:
            raise ValueError("Cannot encrypt empty string")
        salt = os.urandom(16)
        data = plaintext.encode('utf-8')
        key_stream = hashlib.sha256(self._key + salt).digest()
        # Extend key stream to cover data length
        extended_key = key_stream * ((len(data) // len(key_stream)) + 1)
        encrypted = bytes(a ^ b for a, b in zip(data, extended_key[:len(data)]))
        return base64.b64encode(salt + encrypted).decode('ascii')

    def decrypt(self, ciphertext: str) -> str:
        """Decrypt a base64-encoded ciphertext string."""
        if not ciphertext:
            raise ValueError("Cannot decrypt empty string")
        try:
            raw = base64.b64decode(ciphertext)
        except Exception as e:
            raise ValueError("Invalid ciphertext format") from e
        if len(raw) < 17:
            raise ValueError("Ciphertext too short")
        salt = raw[:16]
        encrypted = raw[16:]
        key_stream = hashlib.sha256(self._key + salt).digest()
        extended_key = key_stream * ((len(encrypted) // len(key_stream)) + 1)
        decrypted = bytes(a ^ b for a, b in zip(encrypted, extended_key[:len(encrypted)]))
        return decrypted.decode('utf-8')

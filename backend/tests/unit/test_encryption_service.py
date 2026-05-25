"""Unit tests for EncryptionService."""
import pytest

from app.services.encryption_service import EncryptionService


@pytest.fixture
def service():
    return EncryptionService(secret_key="test-secret-key")


class TestEncryptDecrypt:
    """Tests for encrypt/decrypt roundtrip."""

    def test_roundtrip_simple(self, service):
        """Test encrypt then decrypt returns original text."""
        plaintext = "hello world"
        ciphertext = service.encrypt(plaintext)
        result = service.decrypt(ciphertext)
        assert result == plaintext

    def test_roundtrip_unicode(self, service):
        """Test encrypt/decrypt with unicode characters."""
        plaintext = "Hello, World! 123"
        ciphertext = service.encrypt(plaintext)
        result = service.decrypt(ciphertext)
        assert result == plaintext

    def test_roundtrip_long_string(self, service):
        """Test encrypt/decrypt with a longer string."""
        plaintext = "a" * 500
        ciphertext = service.encrypt(plaintext)
        result = service.decrypt(ciphertext)
        assert result == plaintext

    def test_different_ciphertexts_for_same_input(self, service):
        """Test that encrypting the same text twice produces different ciphertexts."""
        plaintext = "test message"
        ct1 = service.encrypt(plaintext)
        ct2 = service.encrypt(plaintext)
        assert ct1 != ct2

    def test_both_decrypt_to_same_value(self, service):
        """Test that different ciphertexts of same input both decrypt correctly."""
        plaintext = "test message"
        ct1 = service.encrypt(plaintext)
        ct2 = service.encrypt(plaintext)
        assert service.decrypt(ct1) == plaintext
        assert service.decrypt(ct2) == plaintext


class TestEncryptErrors:
    """Tests for encryption error handling."""

    def test_encrypt_empty_string_raises(self, service):
        """Test that encrypting an empty string raises ValueError."""
        with pytest.raises(ValueError, match="Cannot encrypt empty string"):
            service.encrypt("")

    def test_decrypt_empty_string_raises(self, service):
        """Test that decrypting an empty string raises ValueError."""
        with pytest.raises(ValueError, match="Cannot decrypt empty string"):
            service.decrypt("")

    def test_decrypt_invalid_base64_raises(self, service):
        """Test that decrypting invalid base64 raises ValueError."""
        with pytest.raises(ValueError):
            service.decrypt("not-valid-base64!!!")

    def test_decrypt_too_short_raises(self, service):
        """Test that decrypting a too-short ciphertext raises ValueError."""
        import base64
        short = base64.b64encode(b"short").decode()
        with pytest.raises(ValueError, match="Ciphertext too short"):
            service.decrypt(short)

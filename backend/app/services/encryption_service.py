"""Encryption service - AES-256-GCM encryption for API key storage."""

import base64
import logging
import os
from typing import Optional

import httpx
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.config import get_settings

logger = logging.getLogger(__name__)


class EncryptionService:
    """Handles AES-256-GCM encryption of API keys."""

    def __init__(self) -> None:
        """
        Initialize with encryption secret from environment.
        Secret padded/truncated to exactly 32 bytes for AES-256.
        """
        settings = get_settings()
        secret = settings.ENCRYPTION_SECRET.encode()
        self.key = secret[:32].ljust(32, b"0")

    def encrypt(self, plaintext: str) -> dict:
        """
        Encrypt a string using AES-256-GCM.

        Args:
            plaintext: The string to encrypt (e.g., an API key)

        Returns:
            Dict with 'encrypted' and 'iv' fields, both base64 encoded.
        """
        aesgcm = AESGCM(self.key)
        iv = os.urandom(12)
        encrypted = aesgcm.encrypt(iv, plaintext.encode(), None)
        return {
            "encrypted": base64.b64encode(encrypted).decode(),
            "iv": base64.b64encode(iv).decode(),
        }

    def decrypt(self, encrypted: str, iv: str) -> str:
        """
        Decrypt an AES-256-GCM encrypted string.

        Args:
            encrypted: Base64 encoded encrypted data
            iv: Base64 encoded initialization vector

        Returns:
            Decrypted plaintext string

        Raises:
            ValueError: If decryption fails (wrong key or tampered data)
        """
        try:
            aesgcm = AESGCM(self.key)
            encrypted_bytes = base64.b64decode(encrypted)
            iv_bytes = base64.b64decode(iv)
            decrypted = aesgcm.decrypt(iv_bytes, encrypted_bytes, None)
            return decrypted.decode()
        except Exception as e:
            logger.error(f"Decryption failed: {type(e).__name__}")
            raise ValueError("Failed to decrypt key") from e

    def validate_key_format(self, provider: str, key: str) -> bool:
        """
        Validate API key format for a given provider.

        Args:
            provider: Provider name (e.g., 'openai', 'anthropic')
            key: Raw API key string

        Returns:
            True if format looks valid, False otherwise.
            Does NOT verify the key actually works.
        """
        prefixes = {
            "openai": ["sk-"],
            "anthropic": ["sk-ant-"],
            "groq": ["gsk_"],
            "gemini": ["AIza"],
            "openrouter": ["sk-or-"],
            "mistral": [""],
            "cohere": [""],
            "perplexity": ["pplx-"],
            "together": [""],
            "fireworks": ["fw_"],
            "huggingface": ["hf_"],
            "deepseek": ["sk-"],
            "kimi": ["sk-"],
        }

        if provider not in prefixes:
            return len(key) > 10

        valid_prefixes = prefixes[provider]
        if not valid_prefixes or valid_prefixes == [""]:
            return len(key) > 10

        return any(key.startswith(p) for p in valid_prefixes)

    async def test_key(
        self,
        provider: str,
        model: str,
        api_key: str,
    ) -> bool:
        """
        Test if an API key works by sending a minimal request.

        Args:
            provider: Provider name
            model: Model to test with (fallback to cheapest)
            api_key: Raw API key to test

        Returns:
            True if key is valid, False otherwise.
            Never logs the actual key.
        """
        test_models = {
            "openai": "gpt-4o-mini",
            "anthropic": "claude-haiku-4-5-20251001",
            "deepseek": "deepseek-chat",
            "kimi": "moonshot-v1-8k",
            "groq": "llama-3.1-8b-instant",
            "mistral": "mistral-small-latest",
            "gemini": "gemini-2.0-flash",
            "perplexity": "llama-3.1-sonar-small-128k-online",
            "together": "meta-llama/Llama-3-8b-chat-hf",
            "fireworks": "accounts/fireworks/models/llama-v3p1-8b-instruct",
            "openrouter": "openai/gpt-4o-mini",
            "cohere": "command",
            "huggingface": "microsoft/DialoGPT-medium",
        }

        test_message = [{"role": "user", "content": "Hi"}]
        test_model = test_models.get(provider, model)

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                if provider == "anthropic":
                    response = await client.post(
                        "https://api.anthropic.com/v1/messages",
                        headers={
                            "x-api-key": api_key,
                            "anthropic-version": "2023-06-01",
                            "content-type": "application/json",
                        },
                        json={
                            "model": test_model,
                            "messages": test_message,
                            "max_tokens": 1,
                        },
                    )
                elif provider == "gemini":
                    response = await client.post(
                        f"https://generativelanguage.googleapis.com/v1beta/models/{test_model}:generateContent",
                        params={"key": api_key},
                        json={
                            "contents": [{"parts": [{"text": "Hi"}]}],
                        },
                    )
                elif provider == "cohere":
                    response = await client.post(
                        "https://api.cohere.ai/v1/chat",
                        headers={
                            "Authorization": f"Bearer {api_key}",
                            "content-type": "application/json",
                        },
                        json={
                            "model": test_model,
                            "message": "Hi",
                            "max_tokens": 1,
                        },
                    )
                else:
                    base_urls = {
                        "openai": "https://api.openai.com/v1",
                        "deepseek": "https://api.deepseek.com/v1",
                        "kimi": "https://api.moonshot.cn/v1",
                        "groq": "https://api.groq.com/openai/v1",
                        "mistral": "https://api.mistral.ai/v1",
                        "perplexity": "https://api.perplexity.ai",
                        "together": "https://api.together.xyz/v1",
                        "fireworks": "https://api.fireworks.ai/inference/v1",
                        "openrouter": "https://openrouter.ai/api/v1",
                    }
                    base_url = base_urls.get(provider, "")
                    if not base_url:
                        return True  # Can't test unknown providers
                    response = await client.post(
                        f"{base_url}/chat/completions",
                        headers={
                            "Authorization": f"Bearer {api_key}",
                            "content-type": "application/json",
                        },
                        json={
                            "model": test_model,
                            "messages": test_message,
                            "max_tokens": 1,
                        },
                    )

                logger.info(f"Key test for {provider}: status {response.status_code}")
                return response.status_code in [200, 201]

        except Exception as e:
            logger.error(f"Key test failed for {provider}: {type(e).__name__}")
            return False

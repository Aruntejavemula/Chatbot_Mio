"""AI service - routes requests to correct AI provider and streams responses."""

import json
import logging
from typing import AsyncGenerator, Optional

import httpx

logger = logging.getLogger(__name__)

ZERO_FLUFF_PROMPT = """You are a direct, efficient assistant. Never use pleasantries like 'Great question!' or 'Certainly!' or 'Of course!' or 'Sure!'. Never use emojis. Never start with filler phrases. Get straight to the answer immediately. Be concise but complete. No yapping. No padding. No unnecessary words."""

PROVIDER_CONFIGS = {
    "openai": {
        "base_url": "https://api.openai.com/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "anthropic": {
        "base_url": "https://api.anthropic.com",
        "chat_endpoint": "/v1/messages",
        "format": "anthropic",
    },
    "deepseek": {
        "base_url": "https://api.deepseek.com/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "kimi": {
        "base_url": "https://api.moonshot.cn/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "gemini": {
        "base_url": "https://generativelanguage.googleapis.com/v1beta",
        "chat_endpoint": "/models/{model}:streamGenerateContent",
        "format": "gemini",
    },
    "groq": {
        "base_url": "https://api.groq.com/openai/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "together": {
        "base_url": "https://api.together.xyz/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "fireworks": {
        "base_url": "https://api.fireworks.ai/inference/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
    "openrouter": {
        "base_url": "https://openrouter.ai/api/v1",
        "chat_endpoint": "/chat/completions",
        "format": "openai",
    },
}


class AIService:
    """Service for routing AI requests and streaming responses."""

    async def stream_response(
        self,
        provider: str,
        model: str,
        messages: list[dict],
        api_key: str,
        zero_fluff: bool = True,
        max_tokens: int = 4096,
    ) -> AsyncGenerator[str, None]:
        """
        Stream AI response as SSE chunks.

        Args:
            provider: AI provider name
            model: Model identifier
            messages: Chat history
            api_key: Decrypted API key
            zero_fluff: Whether to inject zero-fluff system prompt
            max_tokens: Maximum output tokens

        Yields:
            SSE formatted JSON strings
        """
        if zero_fluff:
            messages = [{"role": "system", "content": ZERO_FLUFF_PROMPT}] + messages

        config = PROVIDER_CONFIGS.get(provider.lower())
        if not config:
            yield f'data: {json.dumps({"type": "error", "error": f"Unknown provider: {provider}"})}\n\n'
            return

        try:
            fmt = config["format"]
            if fmt == "openai":
                async for chunk in self._stream_openai_format(
                    config["base_url"], config["chat_endpoint"], model, messages, api_key, max_tokens
                ):
                    yield chunk
            elif fmt == "anthropic":
                async for chunk in self._stream_anthropic_format(
                    config["base_url"], config["chat_endpoint"], model, messages, api_key, max_tokens
                ):
                    yield chunk
            elif fmt == "gemini":
                async for chunk in self._stream_gemini_format(
                    config["base_url"], config["chat_endpoint"], model, messages, api_key, max_tokens
                ):
                    yield chunk
        except Exception as e:
            logger.error(f"Stream error for {provider}/{model}: {str(e)}")
            yield f'data: {json.dumps({"type": "error", "error": str(e)})}\n\n'

    async def _stream_openai_format(
        self,
        base_url: str,
        endpoint: str,
        model: str,
        messages: list[dict],
        api_key: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        """Handle OpenAI-compatible streaming API."""
        url = f"{base_url}{endpoint}"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        body = {
            "model": model,
            "messages": messages,
            "stream": True,
            "max_tokens": max_tokens,
        }

        tokens_input = 0
        tokens_output = 0

        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream("POST", url, headers=headers, json=body) as response:
                if response.status_code != 200:
                    error_text = ""
                    async for chunk in response.aiter_text():
                        error_text += chunk
                    yield f'data: {json.dumps({"type": "error", "error": f"API error {response.status_code}: {error_text[:200]}"})}\n\n'
                    return

                async for line in response.aiter_lines():
                    if not line or not line.startswith("data: "):
                        continue
                    data_str = line[6:]
                    if data_str.strip() == "[DONE]":
                        break
                    try:
                        data = json.loads(data_str)
                        if "usage" in data:
                            tokens_input = data["usage"].get("prompt_tokens", 0)
                            tokens_output = data["usage"].get("completion_tokens", 0)
                        choices = data.get("choices", [])
                        if choices:
                            delta = choices[0].get("delta", {})
                            content = delta.get("content")
                            if content:
                                yield f'data: {json.dumps({"type": "text", "content": content})}\n\n'
                    except json.JSONDecodeError:
                        continue

        yield f'data: {json.dumps({"type": "done", "tokens": {"input": tokens_input, "output": tokens_output}})}\n\n'

    async def _stream_anthropic_format(
        self,
        base_url: str,
        endpoint: str,
        model: str,
        messages: list[dict],
        api_key: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        """Handle Anthropic streaming API."""
        url = f"{base_url}{endpoint}"

        system_content = ""
        filtered_messages = []
        for msg in messages:
            if msg["role"] == "system":
                system_content += msg["content"] + "\n"
            else:
                filtered_messages.append(msg)

        headers = {
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }
        body = {
            "model": model,
            "messages": filtered_messages,
            "stream": True,
            "max_tokens": max_tokens,
        }
        if system_content:
            body["system"] = system_content.strip()

        tokens_input = 0
        tokens_output = 0

        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream("POST", url, headers=headers, json=body) as response:
                if response.status_code != 200:
                    error_text = ""
                    async for chunk in response.aiter_text():
                        error_text += chunk
                    yield f'data: {json.dumps({"type": "error", "error": f"API error {response.status_code}: {error_text[:200]}"})}\n\n'
                    return

                async for line in response.aiter_lines():
                    if not line or not line.startswith("data: "):
                        continue
                    data_str = line[6:]
                    try:
                        data = json.loads(data_str)
                        event_type = data.get("type", "")
                        if event_type == "content_block_delta":
                            delta = data.get("delta", {})
                            text = delta.get("text", "")
                            if text:
                                yield f'data: {json.dumps({"type": "text", "content": text})}\n\n'
                        elif event_type == "message_delta":
                            usage = data.get("usage", {})
                            tokens_output = usage.get("output_tokens", 0)
                        elif event_type == "message_start":
                            msg = data.get("message", {})
                            usage = msg.get("usage", {})
                            tokens_input = usage.get("input_tokens", 0)
                    except json.JSONDecodeError:
                        continue

        yield f'data: {json.dumps({"type": "done", "tokens": {"input": tokens_input, "output": tokens_output}})}\n\n'

    async def _stream_gemini_format(
        self,
        base_url: str,
        endpoint: str,
        model: str,
        messages: list[dict],
        api_key: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        """Handle Google Gemini streaming API."""
        formatted_endpoint = endpoint.replace("{model}", model)
        url = f"{base_url}{formatted_endpoint}"

        contents = []
        system_text = ""
        for msg in messages:
            if msg["role"] == "system":
                system_text += msg["content"] + "\n"
            elif msg["role"] == "user":
                text = msg["content"]
                if system_text and not contents:
                    text = system_text.strip() + "\n\n" + text
                    system_text = ""
                contents.append({"role": "user", "parts": [{"text": text}]})
            elif msg["role"] == "assistant":
                contents.append({"role": "model", "parts": [{"text": msg["content"]}]})

        params = {"key": api_key, "alt": "sse"}
        body = {
            "contents": contents,
            "generationConfig": {"maxOutputTokens": max_tokens},
        }

        tokens_input = 0
        tokens_output = 0

        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream("POST", url, params=params, json=body) as response:
                if response.status_code != 200:
                    error_text = ""
                    async for chunk in response.aiter_text():
                        error_text += chunk
                    yield f'data: {json.dumps({"type": "error", "error": f"API error {response.status_code}: {error_text[:200]}"})}\n\n'
                    return

                async for line in response.aiter_lines():
                    if not line or not line.startswith("data: "):
                        continue
                    data_str = line[6:]
                    try:
                        data = json.loads(data_str)
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            for part in parts:
                                text = part.get("text", "")
                                if text:
                                    yield f'data: {json.dumps({"type": "text", "content": text})}\n\n'
                        usage_meta = data.get("usageMetadata", {})
                        if usage_meta:
                            tokens_input = usage_meta.get("promptTokenCount", 0)
                            tokens_output = usage_meta.get("candidatesTokenCount", 0)
                    except json.JSONDecodeError:
                        continue

        yield f'data: {json.dumps({"type": "done", "tokens": {"input": tokens_input, "output": tokens_output}})}\n\n'

    async def count_tokens(self, text: str, model: str = "gpt-4o") -> int:
        """
        Rough token count estimate.

        Args:
            text: Text to count tokens for
            model: Model name (unused, for future per-model counting)

        Returns:
            Estimated token count
        """
        return int(len(text.split()) * 1.3)

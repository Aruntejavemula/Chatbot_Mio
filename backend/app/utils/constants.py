"""Application constants - provider list, plan limits, model configs."""

SUPPORTED_PROVIDERS = [
    {
        "id": "openai",
        "name": "OpenAI",
        "models": ["gpt-4o", "gpt-4o-mini", "o1", "o1-mini", "o3-mini"],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "anthropic",
        "name": "Anthropic",
        "models": [
            "claude-opus-4-5",
            "claude-sonnet-4-5",
            "claude-haiku-4-5-20251001",
        ],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "google",
        "name": "Google Gemini",
        "models": [
            "gemini-2.5-pro",
            "gemini-2.5-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash",
        ],
        "requires_key": True,
        "free_tier": True,
    },
    {
        "id": "deepseek",
        "name": "DeepSeek",
        "models": ["deepseek-chat", "deepseek-reasoner"],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "kimi",
        "name": "Kimi (Moonshot)",
        "models": ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "groq",
        "name": "Groq",
        "models": [
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
            "mixtral-8x7b-32768",
            "gemma2-9b-it",
        ],
        "requires_key": True,
        "free_tier": True,
    },
    {
        "id": "mistral",
        "name": "Mistral AI",
        "models": [
            "mistral-large-latest",
            "mistral-small-latest",
            "open-mistral-7b",
            "open-mixtral-8x7b",
        ],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "perplexity",
        "name": "Perplexity",
        "models": [
            "llama-3.1-sonar-large-128k-online",
            "llama-3.1-sonar-small-128k-online",
        ],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "together",
        "name": "Together AI",
        "models": [
            "meta-llama/Llama-3-70b-chat-hf",
            "mistralai/Mixtral-8x7B-Instruct-v0.1",
            "NousResearch/Nous-Hermes-2-Yi-34B",
        ],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "fireworks",
        "name": "Fireworks AI",
        "models": [
            "accounts/fireworks/models/llama-v3p1-70b-instruct",
            "accounts/fireworks/models/mixtral-8x7b-instruct",
        ],
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "openrouter",
        "name": "OpenRouter",
        "models": [],
        "note": "Supports 200+ models via one key",
        "requires_key": True,
        "free_tier": True,
    },
    {
        "id": "cohere",
        "name": "Cohere",
        "models": ["command-r-plus", "command-r", "command"],
        "requires_key": True,
        "free_tier": True,
    },
    {
        "id": "huggingface",
        "name": "HuggingFace",
        "models": [],
        "note": "User specifies model ID",
        "requires_key": True,
        "free_tier": True,
    },
    {
        "id": "ollama",
        "name": "Ollama (Local)",
        "models": [],
        "note": "Runs locally on your machine",
        "requires_key": False,
        "free_tier": True,
    },
    {
        "id": "lmstudio",
        "name": "LM Studio (Local)",
        "models": [],
        "note": "Runs locally on your machine",
        "requires_key": False,
        "free_tier": True,
    },
    {
        "id": "azure_openai",
        "name": "Azure OpenAI",
        "models": [],
        "note": "User provides deployment URL",
        "requires_key": True,
        "free_tier": False,
    },
    {
        "id": "custom",
        "name": "Custom Endpoint",
        "models": [],
        "note": "Any OpenAI-compatible API",
        "requires_key": False,
        "free_tier": True,
    },
]

# Plan limits
DAILY_MESSAGE_LIMITS = {
    "free": 20,
    "basic": 100,
    "pro": -1,
}

DEVICE_LIMITS = {
    "free": 1,
    "basic": 2,
    "pro": 5,
}

STORAGE_TYPE_BY_PLAN = {
    "free": "local",
    "basic": "drive",
    "pro": "cloud",
}

# Token limits for Pro users using our tokens
DAILY_TOKEN_LIMIT = 100_000
MONTHLY_TOKEN_LIMIT = 3_000_000

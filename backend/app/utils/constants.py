"""Application constants - plan limits, model names, and configuration values."""

# Plan names
PLAN_FREE = "free"
PLAN_BASIC = "basic"
PLAN_PRO = "pro"

# Token limits by plan (monthly)
TOKEN_LIMITS = {
    PLAN_FREE: 50_000,
    PLAN_BASIC: 500_000,
    PLAN_PRO: 2_000_000,
}

# Device limits by plan
DEVICE_LIMITS = {
    PLAN_FREE: 1,
    PLAN_BASIC: 3,
    PLAN_PRO: 5,
}

# Available AI models by plan
MODELS_BY_PLAN = {
    PLAN_FREE: ["gpt-3.5-turbo"],
    PLAN_BASIC: ["gpt-3.5-turbo", "gpt-4"],
    PLAN_PRO: ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo", "claude-3-opus"],
}

# Rate limiting
RATE_LIMIT_REQUESTS = 60
RATE_LIMIT_WINDOW = 60  # seconds

# Supported providers for API keys
SUPPORTED_PROVIDERS = ["openai", "anthropic", "google"]

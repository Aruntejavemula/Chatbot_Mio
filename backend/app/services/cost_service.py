"""Cost tracking and anomaly detection service for AI model usage."""

import logging
from collections import defaultdict
from datetime import date
from typing import Any

logger = logging.getLogger(__name__)

# Cost per 1K tokens (input, output) in USD
COST_RATES: dict[str, dict[str, float]] = {
    "deepseek-chat": {"input": 0.00014, "output": 0.00028},
    "deepseek-reasoner": {"input": 0.00055, "output": 0.0022},
    "claude-opus-4-5": {"input": 0.015, "output": 0.075},
    "claude-sonnet-4-5": {"input": 0.003, "output": 0.015},
    "claude-haiku-4-5": {"input": 0.0008, "output": 0.004},
    "gpt-4o": {"input": 0.0025, "output": 0.01},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
    "gemini-2.5-pro": {"input": 0.00125, "output": 0.01},
    "gemini-2.5-flash": {"input": 0.000075, "output": 0.0003},
    "default": {"input": 0.001, "output": 0.002},
}

# Daily spending thresholds in USD
SOFT_ALERT_USD: float = 10.0
HARD_BLOCK_USD: float = 20.0
EMERGENCY_USD: float = 50.0

# In-memory cost tracking (placeholder for Redis)
_daily_costs: dict[str, dict[str, float]] = defaultdict(lambda: defaultdict(float))


class CostService:
    """Service for tracking and managing AI model usage costs."""

    def calculate_cost(
        self, model: str, input_tokens: int, output_tokens: int
    ) -> float:
        """Calculate the cost for a given model and token usage.

        Args:
            model: The AI model identifier.
            input_tokens: Number of input tokens consumed.
            output_tokens: Number of output tokens generated.

        Returns:
            Total cost in USD.
        """
        try:
            rates = COST_RATES.get(model, COST_RATES["default"])
            input_cost = (input_tokens / 1000) * rates["input"]
            output_cost = (output_tokens / 1000) * rates["output"]
            total = round(input_cost + output_cost, 6)
            logger.debug(
                "Cost calculated for model=%s: input=%d, output=%d, total=$%.6f",
                model,
                input_tokens,
                output_tokens,
                total,
            )
            return total
        except Exception as exc:
            logger.error("Error calculating cost for model=%s: %s", model, str(exc))
            return 0.0

    def track_cost(
        self, user_id: str, model: str, input_tokens: int, output_tokens: int
    ) -> dict[str, Any]:
        """Track cost for a user request and check thresholds.

        Args:
            user_id: The user identifier.
            model: The AI model used.
            input_tokens: Number of input tokens consumed.
            output_tokens: Number of output tokens generated.

        Returns:
            Dictionary with cost details and threshold status.
        """
        try:
            cost = self.calculate_cost(model, input_tokens, output_tokens)
            today = date.today().isoformat()
            key = f"{user_id}:{today}"
            _daily_costs[key]["total"] += cost
            _daily_costs[key]["requests"] += 1

            daily_total = _daily_costs[key]["total"]

            status = "ok"
            if daily_total >= EMERGENCY_USD:
                status = "emergency"
                logger.critical(
                    "EMERGENCY: user=%s daily cost=$%.2f exceeds $%.2f",
                    user_id,
                    daily_total,
                    EMERGENCY_USD,
                )
            elif daily_total >= HARD_BLOCK_USD:
                status = "blocked"
                logger.warning(
                    "HARD BLOCK: user=%s daily cost=$%.2f exceeds $%.2f",
                    user_id,
                    daily_total,
                    HARD_BLOCK_USD,
                )
            elif daily_total >= SOFT_ALERT_USD:
                status = "alert"
                logger.info(
                    "SOFT ALERT: user=%s daily cost=$%.2f exceeds $%.2f",
                    user_id,
                    daily_total,
                    SOFT_ALERT_USD,
                )

            return {
                "cost": cost,
                "daily_total": round(daily_total, 6),
                "status": status,
                "requests_today": int(_daily_costs[key]["requests"]),
            }
        except Exception as exc:
            logger.error(
                "Error tracking cost for user=%s: %s", user_id, str(exc)
            )
            return {"cost": 0.0, "daily_total": 0.0, "status": "error", "requests_today": 0}

    def get_daily_cost(self, user_id: str) -> dict[str, Any]:
        """Get the current daily cost for a user.

        Args:
            user_id: The user identifier.

        Returns:
            Dictionary with daily cost information.
        """
        try:
            today = date.today().isoformat()
            key = f"{user_id}:{today}"
            daily_total = _daily_costs[key]["total"]
            requests = int(_daily_costs[key]["requests"])

            logger.debug(
                "Daily cost for user=%s: $%.6f (%d requests)",
                user_id,
                daily_total,
                requests,
            )
            return {
                "user_id": user_id,
                "date": today,
                "total_cost": round(daily_total, 6),
                "requests": requests,
            }
        except Exception as exc:
            logger.error(
                "Error getting daily cost for user=%s: %s", user_id, str(exc)
            )
            return {"user_id": user_id, "date": date.today().isoformat(), "total_cost": 0.0, "requests": 0}

    def check_anomaly(
        self, user_id: str, current_tokens: int, model: str
    ) -> dict[str, Any]:
        """Check if current usage indicates anomalous behavior.

        Detects abnormal token usage patterns that may indicate abuse
        or compromised accounts.

        Args:
            user_id: The user identifier.
            current_tokens: Token count for the current request.
            model: The AI model being used.

        Returns:
            Dictionary with anomaly detection results.
        """
        try:
            # Anomaly thresholds
            max_single_request_tokens = 100_000
            max_daily_requests = 500

            is_anomaly = False
            reasons: list[str] = []

            # Check single request token spike
            if current_tokens > max_single_request_tokens:
                is_anomaly = True
                reasons.append(
                    f"Single request tokens ({current_tokens}) exceeds threshold ({max_single_request_tokens})"
                )

            # Check daily request count
            today = date.today().isoformat()
            key = f"{user_id}:{today}"
            daily_requests = int(_daily_costs[key]["requests"])
            if daily_requests > max_daily_requests:
                is_anomaly = True
                reasons.append(
                    f"Daily requests ({daily_requests}) exceeds threshold ({max_daily_requests})"
                )

            # Check daily cost threshold
            daily_total = _daily_costs[key]["total"]
            if daily_total > EMERGENCY_USD:
                is_anomaly = True
                reasons.append(
                    f"Daily cost (${daily_total:.2f}) exceeds emergency threshold (${EMERGENCY_USD:.2f})"
                )

            if is_anomaly:
                logger.warning(
                    "Anomaly detected for user=%s model=%s: %s",
                    user_id,
                    model,
                    "; ".join(reasons),
                )

            return {
                "is_anomaly": is_anomaly,
                "reasons": reasons,
                "user_id": user_id,
                "model": model,
                "current_tokens": current_tokens,
            }
        except Exception as exc:
            logger.error(
                "Error checking anomaly for user=%s: %s", user_id, str(exc)
            )
            return {
                "is_anomaly": False,
                "reasons": [],
                "user_id": user_id,
                "model": model,
                "current_tokens": current_tokens,
            }

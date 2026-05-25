"""Agent service for multi-step AI task execution with tool calling."""

import json
import logging
from typing import Any, AsyncGenerator

from app.services.skills.skill_registry import skill_registry

logger = logging.getLogger(__name__)

MAX_ITERATIONS = 10


class AgentService:
    """Service for running multi-step agent loops with tool calling.

    Executes an iterative loop where the AI model can call tools (skills)
    and receive results, continuing until the task is complete or the
    maximum iteration count is reached.
    """

    def __init__(self) -> None:
        """Initialize the agent service."""
        self._max_iterations = MAX_ITERATIONS

    async def run(
        self,
        messages: list[dict[str, str]],
        provider: str,
        model: str,
        api_key: str,
        user_id: str,
        plan: str = "free",
    ) -> AsyncGenerator[str, None]:
        """Run the agent loop, yielding SSE events.

        Executes a tool-calling loop for up to MAX_ITERATIONS. Each iteration:
        1. Calls the AI model with available tools
        2. If the model returns a tool call, executes the skill
        3. Appends the tool result and continues
        4. If no tool call, yields the final text response

        Yields SSE-formatted events:
        - agent_step: indicates a tool is being called
        - text: partial or complete text response
        - done: agent loop completed successfully
        - agent_error: an error occurred during execution

        Args:
            messages: Conversation history.
            provider: AI provider name.
            model: Model identifier.
            api_key: User's API key for the provider.
            user_id: The authenticated user's ID.
            plan: User's subscription plan for skill access.

        Yields:
            SSE-formatted event strings.
        """
        try:
            tools = skill_registry.get_tool_definitions(plan)
            iteration = 0

            while iteration < self._max_iterations:
                iteration += 1
                logger.info(
                    "Agent iteration %d/%d for user=%s",
                    iteration,
                    self._max_iterations,
                    user_id,
                )

                # Placeholder: in production, call the AI model here
                # For now, simulate a single-pass response with no tool calls
                simulated_response = {
                    "type": "text",
                    "content": "Agent response placeholder. No tool calls needed.",
                    "tool_calls": None,
                }

                tool_calls = simulated_response.get("tool_calls")

                if tool_calls:
                    for tool_call in tool_calls:
                        skill_name = tool_call.get("name", "unknown")
                        arguments = tool_call.get("arguments", {})

                        # Yield agent_step event
                        step_event = {
                            "type": "agent_step",
                            "skill": skill_name,
                            "arguments": arguments,
                            "iteration": iteration,
                        }
                        yield f"data: {json.dumps(step_event)}\n\n"

                        # Execute the skill
                        result = await self.execute_skill(
                            skill_name=skill_name,
                            arguments=arguments,
                            user_id=user_id,
                        )

                        # Append tool result to messages for next iteration
                        messages.append({
                            "role": "tool",
                            "content": json.dumps(result),
                            "name": skill_name,
                        })
                else:
                    # No tool calls - yield text response and finish
                    content = simulated_response.get("content", "")
                    text_event = {"type": "text", "content": content}
                    yield f"data: {json.dumps(text_event)}\n\n"

                    done_event = {
                        "type": "done",
                        "iterations": iteration,
                        "tokens": {"input": 0, "output": 0},
                    }
                    yield f"data: {json.dumps(done_event)}\n\n"
                    return

            # Max iterations reached
            logger.warning("Agent reached max iterations for user=%s", user_id)
            done_event = {
                "type": "done",
                "iterations": iteration,
                "max_reached": True,
                "tokens": {"input": 0, "output": 0},
            }
            yield f"data: {json.dumps(done_event)}\n\n"

        except Exception as e:
            logger.error("Agent error for user=%s: %s", user_id, str(e))
            error_event = {"type": "agent_error", "error": str(e)}
            yield f"data: {json.dumps(error_event)}\n\n"

    async def execute_skill(
        self,
        skill_name: str,
        arguments: dict[str, Any],
        user_id: str,
    ) -> dict[str, Any]:
        """Execute a registered skill by name.

        Looks up the skill in the registry and invokes it with the
        provided arguments.

        Args:
            skill_name: Name of the skill to execute.
            arguments: Dictionary of arguments to pass to the skill.
            user_id: The user requesting the skill execution.

        Returns:
            Dictionary with the skill execution result or error.
        """
        try:
            skill = skill_registry.get(skill_name)
            if not skill:
                logger.warning("Skill not found: %s (user=%s)", skill_name, user_id)
                return {"error": f"Skill '{skill_name}' not found"}

            logger.info("Executing skill=%s for user=%s", skill_name, user_id)
            result = await skill.execute(**arguments)
            return {"result": result}
        except Exception as e:
            logger.error("Skill execution error (%s) for user=%s: %s", skill_name, user_id, str(e))
            return {"error": f"Skill execution failed: {str(e)}"}


# Global instance
agent_service = AgentService()

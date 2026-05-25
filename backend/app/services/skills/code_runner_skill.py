"""Code runner skill - executes Python code in a sandboxed subprocess."""

import logging
import subprocess
from typing import Any

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)

# Forbidden imports/keywords for security
FORBIDDEN = [
    "import os",
    "import sys",
    "import subprocess",
    "import shutil",
    "import socket",
    "import requests",
    "import urllib",
    "import http",
    "__import__",
    "eval(",
    "exec(",
    "open(",
    "compile(",
    "globals(",
    "locals(",
    "getattr(",
    "setattr(",
    "delattr(",
    "breakpoint(",
]

MAX_OUTPUT_LENGTH = 2000
TIMEOUT_SECONDS = 10


class CodeRunnerSkill(BaseSkill):
    """Skill for executing Python code safely."""

    name = "code_runner"
    description = "Execute Python code and return the output"
    parameters = {
        "type": "object",
        "properties": {
            "code": {
                "type": "string",
                "description": "Python code to execute",
            },
            "language": {
                "type": "string",
                "enum": ["python"],
                "description": "Programming language (only python supported)",
            },
        },
        "required": ["code"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Execute Python code in a subprocess with safety checks.

        Args:
            params: Dictionary with 'code' and optional 'language'.

        Returns:
            Dictionary with stdout, stderr, and success status.
        """
        code = params.get("code", "")
        language = params.get("language", "python")

        if not code:
            return {"error": "Code is required", "success": False}

        if language != "python":
            return {"error": f"Unsupported language: {language}", "success": False}

        # Security check
        for forbidden in FORBIDDEN:
            if forbidden in code:
                return {
                    "error": f"Forbidden operation detected: {forbidden}",
                    "success": False,
                }

        try:
            result = subprocess.run(
                ["python", "-c", code],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS,
            )

            stdout = result.stdout[:MAX_OUTPUT_LENGTH]
            stderr = result.stderr[:MAX_OUTPUT_LENGTH]

            if len(result.stdout) > MAX_OUTPUT_LENGTH:
                stdout += "\n... (output truncated)"
            if len(result.stderr) > MAX_OUTPUT_LENGTH:
                stderr += "\n... (output truncated)"

            return {
                "stdout": stdout,
                "stderr": stderr,
                "exit_code": result.returncode,
                "success": result.returncode == 0,
            }

        except subprocess.TimeoutExpired:
            return {
                "error": f"Execution timed out after {TIMEOUT_SECONDS} seconds",
                "success": False,
            }
        except Exception as e:
            logger.error("Code execution error: %s", str(e))
            return {
                "error": f"Execution failed: {str(e)}",
                "success": False,
            }

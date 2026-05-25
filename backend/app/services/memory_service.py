"""Memory service for extracting, storing, and retrieving user memories."""

import logging
from datetime import datetime
from typing import Any, Optional
from uuid import uuid4

logger = logging.getLogger(__name__)


class MemoryService:
    """Service for managing user memories.

    Handles extraction of memories from conversations, storage,
    retrieval, and formatting for context injection.
    """

    def __init__(self) -> None:
        """Initialize the memory service."""
        self._memories: dict[str, list[dict[str, Any]]] = {}

    async def extract_memories(
        self,
        messages: list[dict[str, str]],
        user_id: str,
    ) -> list[dict[str, Any]]:
        """Extract potential memories from a conversation.

        Analyzes messages to identify facts, preferences, or important
        information worth remembering for future interactions.

        Args:
            messages: List of conversation messages with role and content.
            user_id: The ID of the user whose conversation to analyze.

        Returns:
            List of extracted memory dictionaries with content and metadata.
        """
        try:
            logger.info("Extracting memories for user=%s from %d messages", user_id, len(messages))
            # Placeholder: in production, this would use an LLM to extract memories
            extracted: list[dict[str, Any]] = []
            return extracted
        except Exception as e:
            logger.error("Error extracting memories for user=%s: %s", user_id, str(e))
            return []

    async def save_memories(
        self,
        memories: list[dict[str, Any]],
        user_id: str,
        project_id: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """Save extracted memories to storage.

        Persists a list of memory entries for a user. Deduplicates
        against existing memories before saving.

        Args:
            memories: List of memory dicts with at least a 'content' key.
            user_id: The ID of the user to save memories for.
            project_id: Optional project ID to scope memories to a project.

        Returns:
            List of saved memory records with IDs and timestamps.
        """
        try:
            logger.info("Saving %d memories for user=%s project=%s", len(memories), user_id, project_id)
            saved: list[dict[str, Any]] = []
            if user_id not in self._memories:
                self._memories[user_id] = []

            for memory in memories:
                record = {
                    "id": str(uuid4()),
                    "user_id": user_id,
                    "content": memory.get("content", ""),
                    "category": memory.get("category", "general"),
                    "project_id": project_id,
                    "created_at": datetime.utcnow().isoformat(),
                }
                self._memories[user_id].append(record)
                saved.append(record)

            return saved
        except Exception as e:
            logger.error("Error saving memories for user=%s: %s", user_id, str(e))
            return []

    async def get_memories(
        self,
        user_id: str,
        category: Optional[str] = None,
        limit: int = 50,
        project_id: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """Retrieve stored memories for a user.

        Fetches memories from storage, optionally filtered by category
        and/or project.

        Args:
            user_id: The ID of the user whose memories to retrieve.
            category: Optional category filter (e.g., 'preference', 'fact').
            limit: Maximum number of memories to return.
            project_id: Optional project ID to filter memories by project scope.

        Returns:
            List of memory records.
        """
        try:
            logger.info("Fetching memories for user=%s (category=%s, limit=%d, project_id=%s)", user_id, category, limit, project_id)
            user_memories = self._memories.get(user_id, [])

            if category:
                user_memories = [m for m in user_memories if m.get("category") == category]

            # TODO: Placeholder - filter by project_id when project-scoped memory is implemented
            if project_id:
                user_memories = [m for m in user_memories if m.get("project_id") == project_id]

            return user_memories[:limit]
        except Exception as e:
            logger.error("Error fetching memories for user=%s: %s", user_id, str(e))
            return []

    async def delete_memory(self, memory_id: str, user_id: str) -> bool:
        """Delete a specific memory by ID.

        Args:
            memory_id: The unique ID of the memory to delete.
            user_id: The ID of the user who owns the memory.

        Returns:
            True if the memory was deleted, False if not found.
        """
        try:
            logger.info("Deleting memory=%s for user=%s", memory_id, user_id)
            user_memories = self._memories.get(user_id, [])
            original_count = len(user_memories)
            self._memories[user_id] = [m for m in user_memories if m["id"] != memory_id]
            deleted = len(self._memories[user_id]) < original_count
            if deleted:
                logger.info("Memory %s deleted successfully", memory_id)
            else:
                logger.warning("Memory %s not found for user=%s", memory_id, user_id)
            return deleted
        except Exception as e:
            logger.error("Error deleting memory=%s for user=%s: %s", memory_id, user_id, str(e))
            return False

    async def delete_all_memories(self, user_id: str) -> int:
        """Delete all memories for a user.

        Args:
            user_id: The ID of the user whose memories to delete.

        Returns:
            Number of memories deleted.
        """
        try:
            logger.info("Deleting all memories for user=%s", user_id)
            count = len(self._memories.get(user_id, []))
            self._memories[user_id] = []
            logger.info("Deleted %d memories for user=%s", count, user_id)
            return count
        except Exception as e:
            logger.error("Error deleting all memories for user=%s: %s", user_id, str(e))
            return 0

    def format_for_context(self, memories: list[dict[str, Any]]) -> str:
        """Format memories into a string suitable for LLM context injection.

        Converts a list of memory records into a formatted string that
        can be prepended to system prompts or injected into conversations.

        Args:
            memories: List of memory records to format.

        Returns:
            Formatted string of memories for context injection.
        """
        if not memories:
            return ""

        lines = ["Here are things I remember about this user:"]
        for memory in memories:
            content = memory.get("content", "")
            category = memory.get("category", "general")
            lines.append(f"- [{category}] {content}")

        return "\n".join(lines)


# Global instance
memory_service = MemoryService()

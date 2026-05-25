"""Memory router - endpoints for managing user memories."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user
from app.services.memory_service import memory_service

logger = logging.getLogger(__name__)

router = APIRouter()


class MemoryCreate(BaseModel):
    """Request model for creating a memory."""

    content: str = Field(..., description="Memory content text", min_length=1, max_length=2000)
    category: str = Field(default="general", description="Memory category (e.g., preference, fact, general)")


class MemoryResponse(BaseModel):
    """Response model for a memory entry."""

    id: str
    user_id: str
    content: str
    category: str
    created_at: str


@router.get("")
async def list_memories(
    category: Optional[str] = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """List memories for the current user.

    Optionally filter by category and limit results.

    Args:
        category: Optional category filter.
        limit: Maximum number of memories to return.
        current_user: Authenticated user.

    Returns:
        Dictionary with list of memories.
    """
    user_id = current_user["id"]
    try:
        memories = await memory_service.get_memories(
            user_id=user_id,
            category=category,
            limit=limit,
        )
        return {"memories": memories, "count": len(memories)}
    except Exception as e:
        logger.error("Error listing memories for user=%s: %s", user_id, str(e))
        raise HTTPException(status_code=500, detail="Failed to fetch memories")


@router.post("")
async def create_memory(
    body: MemoryCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Create a new memory for the current user.

    Args:
        body: Memory creation request with content and category.
        current_user: Authenticated user.

    Returns:
        The created memory record.
    """
    user_id = current_user["id"]
    try:
        saved = await memory_service.save_memories(
            memories=[{"content": body.content, "category": body.category}],
            user_id=user_id,
        )
        if not saved:
            raise HTTPException(status_code=500, detail="Failed to save memory")
        logger.info("Memory created for user=%s", user_id)
        return {"memory": saved[0]}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error creating memory for user=%s: %s", user_id, str(e))
        raise HTTPException(status_code=500, detail="Failed to create memory")


@router.delete("/{memory_id}")
async def delete_memory(
    memory_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Delete a specific memory by ID.

    Args:
        memory_id: The ID of the memory to delete.
        current_user: Authenticated user.

    Returns:
        Confirmation message.
    """
    user_id = current_user["id"]
    try:
        deleted = await memory_service.delete_memory(memory_id=memory_id, user_id=user_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Memory not found")
        return {"message": "Memory deleted"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error deleting memory=%s for user=%s: %s", memory_id, user_id, str(e))
        raise HTTPException(status_code=500, detail="Failed to delete memory")


@router.delete("/all")
async def delete_all_memories(
    current_user: dict = Depends(get_current_user),
    x_confirm_delete: Optional[str] = Header(None, alias="X-Confirm-Delete"),
) -> dict:
    """Delete all memories for the current user.

    Requires X-Confirm-Delete header set to 'true' as a safety measure.

    Args:
        current_user: Authenticated user.
        x_confirm_delete: Confirmation header value.

    Returns:
        Confirmation with count of deleted memories.
    """
    if x_confirm_delete != "true":
        raise HTTPException(
            status_code=400,
            detail="X-Confirm-Delete header must be set to 'true' to confirm deletion",
        )

    user_id = current_user["id"]
    try:
        count = await memory_service.delete_all_memories(user_id=user_id)
        logger.info("Deleted all (%d) memories for user=%s", count, user_id)
        return {"message": "All memories deleted", "count": count}
    except Exception as e:
        logger.error("Error deleting all memories for user=%s: %s", user_id, str(e))
        raise HTTPException(status_code=500, detail="Failed to delete memories")

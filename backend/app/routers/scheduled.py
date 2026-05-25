"""Scheduled tasks router - CRUD for user-scheduled tasks."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


class ScheduledTaskCreate(BaseModel):
    """Request model for creating a scheduled task."""

    title: str = Field(..., description="Task title", min_length=1, max_length=200)
    prompt: str = Field(..., description="Prompt to execute", min_length=1, max_length=5000)
    schedule_type: str = Field(..., description="Schedule type: once, daily, weekly")
    run_at: Optional[str] = Field(None, description="ISO datetime for one-time tasks")
    run_time: Optional[str] = Field(None, description="Time of day (HH:MM) for recurring tasks")
    run_day: Optional[str] = Field(None, description="Day of week for weekly tasks")


class ScheduledTaskUpdate(BaseModel):
    """Request model for updating a scheduled task."""

    title: Optional[str] = Field(None, min_length=1, max_length=200)
    prompt: Optional[str] = Field(None, min_length=1, max_length=5000)
    schedule_type: Optional[str] = None
    run_at: Optional[str] = None
    run_time: Optional[str] = None
    run_day: Optional[str] = None


@router.get("/scheduled")
async def list_scheduled_tasks(
    current_user: dict = Depends(get_current_user),
) -> list[dict]:
    """List all scheduled tasks for the current user.

    Args:
        current_user: Authenticated user.

    Returns:
        List of scheduled task objects.
    """
    user_id = current_user["id"]
    logger.info("Listing scheduled tasks for user=%s", user_id)
    # Placeholder: return empty list until persistence is wired up
    return []


@router.post("/scheduled")
async def create_scheduled_task(
    body: ScheduledTaskCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Create a new scheduled task.

    Args:
        body: Scheduled task creation data.
        current_user: Authenticated user.

    Returns:
        Created scheduled task object.
    """
    user_id = current_user["id"]

    if body.schedule_type not in ("once", "daily", "weekly"):
        raise HTTPException(status_code=400, detail="schedule_type must be once, daily, or weekly")

    logger.info("Creating scheduled task for user=%s, title=%s", user_id, body.title)

    # Placeholder response
    return {
        "id": "placeholder-task-id",
        "user_id": user_id,
        "title": body.title,
        "prompt": body.prompt,
        "schedule_type": body.schedule_type,
        "run_at": body.run_at,
        "run_time": body.run_time,
        "run_day": body.run_day,
        "status": "active",
    }


@router.patch("/scheduled/{task_id}")
async def update_scheduled_task(
    task_id: str,
    body: ScheduledTaskUpdate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Update an existing scheduled task.

    Args:
        task_id: The scheduled task ID.
        body: Fields to update.
        current_user: Authenticated user.

    Returns:
        Updated scheduled task object.
    """
    user_id = current_user["id"]
    logger.info("Updating scheduled task=%s for user=%s", task_id, user_id)

    # Placeholder response
    return {
        "id": task_id,
        "user_id": user_id,
        "status": "updated",
    }


@router.delete("/scheduled/{task_id}")
async def delete_scheduled_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Delete a scheduled task.

    Args:
        task_id: The scheduled task ID.
        current_user: Authenticated user.

    Returns:
        Confirmation message.
    """
    user_id = current_user["id"]
    logger.info("Deleting scheduled task=%s for user=%s", task_id, user_id)

    # Placeholder response
    return {"message": "Scheduled task deleted", "id": task_id}

"""Projects router for organizing chats into collections (Pro plan feature)."""

import logging
import re
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator

from app.middleware.auth import get_current_user
from app.middleware.rate_limit import rate_limit

logger = logging.getLogger(__name__)

router = APIRouter()

# Rate limit constants
CREATE_RATE_LIMIT_MAX: int = 10
CREATE_RATE_LIMIT_WINDOW: int = 60
LIST_RATE_LIMIT_MAX: int = 30
LIST_RATE_LIMIT_WINDOW: int = 60

# Default project color
DEFAULT_PROJECT_COLOR: str = "#CC5801"


class ProjectCreateRequest(BaseModel):
    """Request model for creating a new project."""

    name: str = Field(..., min_length=1, max_length=100)
    color: str = Field(default=DEFAULT_PROJECT_COLOR, max_length=7)
    system_prompt: str = Field(default="", max_length=5000)

    @field_validator("color")
    @classmethod
    def validate_hex_color(cls, value: str) -> str:
        """Validate that color is a valid hex color string (#RRGGBB)."""
        if not re.match(r"^#[0-9a-fA-F]{6}$", value):
            raise ValueError("color must be a valid hex color (e.g. #CC5801)")
        return value


class ProjectUpdateRequest(BaseModel):
    """Request model for updating a project."""

    name: str | None = Field(default=None, min_length=1, max_length=100)
    color: str | None = Field(default=None, max_length=7)
    system_prompt: str | None = Field(default=None, max_length=5000)

    @field_validator("color")
    @classmethod
    def validate_hex_color(cls, value: str | None) -> str | None:
        """Validate that color is a valid hex color string (#RRGGBB)."""
        if value is not None and not re.match(r"^#[0-9a-fA-F]{6}$", value):
            raise ValueError("color must be a valid hex color (e.g. #CC5801)")
        return value


class ProjectResponse(BaseModel):
    """Response model for a single project."""

    id: str
    user_id: str
    name: str
    color: str
    system_prompt: str
    created_at: str
    updated_at: str


class ProjectListResponse(BaseModel):
    """Response model for a list of projects."""

    projects: list[ProjectResponse]


class ChatResponse(BaseModel):
    """Response model for a chat within a project."""

    id: str
    title: str
    updated_at: str


class ProjectChatsResponse(BaseModel):
    """Response model for chats in a project."""

    chats: list[ChatResponse]


def _check_pro_plan(current_user: dict[str, Any]) -> None:
    """Verify the user has a Pro plan subscription.

    Args:
        current_user: The authenticated user dict.

    Raises:
        HTTPException: If the user does not have a Pro plan (403).
    """
    # NOTE: The auth middleware (app/middleware/auth.py) currently returns only
    # {"user_id": token[:8]} and does not include a "plan" field. Once the
    # database is connected, the auth middleware must be updated to fetch and
    # include the user's subscription plan in the returned dict so this gate
    # can function correctly. Until then, all requests will default to "free"
    # and receive a 403 response.
    plan = current_user.get("plan", "free")
    if plan != "pro":
        logger.warning(
            "Non-pro user attempted projects access: user=%s",
            current_user.get("user_id"),
        )
        raise HTTPException(
            status_code=403,
            detail="Projects feature requires a Pro plan subscription.",
        )


def _check_project_ownership(
    project_owner_id: str, current_user_id: str
) -> None:
    """Verify the current user owns the project.

    Args:
        project_owner_id: The user_id of the project owner.
        current_user_id: The user_id of the current user.

    Raises:
        HTTPException: If the user does not own the project (403).
    """
    if project_owner_id != current_user_id:
        logger.warning(
            "User %s attempted to access project owned by %s",
            current_user_id,
            project_owner_id,
        )
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to access this project.",
        )


@router.post(
    "/",
    response_model=ProjectResponse,
    summary="Create a new project",
    status_code=201,
)
async def create_project(
    body: ProjectCreateRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=CREATE_RATE_LIMIT_MAX,
            window_seconds=CREATE_RATE_LIMIT_WINDOW,
        )
    ),
) -> ProjectResponse:
    """Create a new project for the authenticated Pro user.

    Projects allow users to organize their chats into collections
    with custom names, colors, and system prompts.

    Args:
        body: The project creation request body.
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        ProjectResponse containing the created project details.

    Raises:
        HTTPException: On auth errors (401), non-pro plan (403),
            or rate limit errors (429).
    """
    _check_pro_plan(current_user)

    user_id = current_user.get("user_id", "unknown")
    logger.info(
        "Creating project for user=%s, name=%s",
        user_id,
        body.name,
    )

    # Placeholder: Insert into projects table via Supabase client
    # project = await supabase.table("projects").insert({
    #     "user_id": user_id,
    #     "name": body.name,
    #     "color": body.color,
    #     "system_prompt": body.system_prompt,
    # }).execute()

    # Placeholder response until database is connected
    return ProjectResponse(
        id="placeholder-uuid",
        user_id=user_id,
        name=body.name,
        color=body.color,
        system_prompt=body.system_prompt,
        created_at="2024-01-01T00:00:00Z",
        updated_at="2024-01-01T00:00:00Z",
    )


@router.get(
    "/",
    response_model=ProjectListResponse,
    summary="List all projects for the current user",
)
async def list_projects(
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=LIST_RATE_LIMIT_MAX,
            window_seconds=LIST_RATE_LIMIT_WINDOW,
        )
    ),
) -> ProjectListResponse:
    """List all projects for the authenticated Pro user.

    Returns projects ordered by created_at descending (newest first).

    Args:
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        ProjectListResponse containing a list of the user's projects.

    Raises:
        HTTPException: On auth errors (401), non-pro plan (403),
            or rate limit errors (429).
    """
    _check_pro_plan(current_user)

    user_id = current_user.get("user_id", "unknown")
    logger.info("Listing projects for user=%s", user_id)

    # Placeholder: Query projects table via Supabase client
    # projects = await supabase.table("projects") \
    #     .select("*") \
    #     .eq("user_id", user_id) \
    #     .order("created_at", desc=True) \
    #     .execute()

    # Placeholder response until database is connected
    return ProjectListResponse(projects=[])


@router.patch(
    "/{project_id}",
    response_model=ProjectResponse,
    summary="Update a project",
)
async def update_project(
    project_id: UUID,
    body: ProjectUpdateRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=CREATE_RATE_LIMIT_MAX,
            window_seconds=CREATE_RATE_LIMIT_WINDOW,
        )
    ),
) -> ProjectResponse:
    """Update a project owned by the authenticated Pro user.

    Only the fields provided in the request body will be updated.
    The user must own the project to update it.

    Args:
        project_id: The UUID of the project to update.
        body: The project update request body with optional fields.
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        ProjectResponse containing the updated project details.

    Raises:
        HTTPException: On auth errors (401), non-pro plan (403),
            project not found (404), or rate limit errors (429).
    """
    _check_pro_plan(current_user)

    user_id = current_user.get("user_id", "unknown")
    logger.info(
        "Updating project=%s for user=%s",
        project_id,
        user_id,
    )

    # Placeholder: Fetch project from database to verify existence and ownership
    # project = await supabase.table("projects") \
    #     .select("*") \
    #     .eq("id", str(project_id)) \
    #     .single() \
    #     .execute()

    # TODO: Replace with actual Supabase query once the database client is wired.
    # This placeholder always returns None, making the endpoint always 404.
    # The code below (ownership check, update logic, response) will become
    # reachable once this line returns real query results.
    # Placeholder: Simulate project not found check
    project_data: dict[str, Any] | None = None  # Would come from DB query

    if project_data is None:
        raise HTTPException(
            status_code=404,
            detail="Project not found.",
        )

    _check_project_ownership(project_data.get("user_id", ""), user_id)

    # Build update payload with only provided fields
    update_fields: dict[str, Any] = {}
    if body.name is not None:
        update_fields["name"] = body.name
    if body.color is not None:
        update_fields["color"] = body.color
    if body.system_prompt is not None:
        update_fields["system_prompt"] = body.system_prompt

    if not update_fields:
        logger.info("No fields to update for project=%s", project_id)
        # Return existing project data unchanged
        return ProjectResponse(
            id=str(project_id),
            user_id=user_id,
            name=project_data.get("name", ""),
            color=project_data.get("color", DEFAULT_PROJECT_COLOR),
            system_prompt=project_data.get("system_prompt", ""),
            created_at=project_data.get("created_at", ""),
            updated_at=project_data.get("updated_at", ""),
        )

    # Placeholder: Update project in database via Supabase client
    # updated = await supabase.table("projects") \
    #     .update(update_fields) \
    #     .eq("id", str(project_id)) \
    #     .execute()

    return ProjectResponse(
        id=str(project_id),
        user_id=user_id,
        name=body.name or project_data.get("name", ""),
        color=body.color or project_data.get("color", DEFAULT_PROJECT_COLOR),
        system_prompt=(
            body.system_prompt
            if body.system_prompt is not None
            else project_data.get("system_prompt", "")
        ),
        created_at=project_data.get("created_at", ""),
        updated_at="2024-01-01T00:00:00Z",
    )


@router.delete(
    "/{project_id}",
    status_code=204,
    summary="Delete a project",
)
async def delete_project(
    project_id: UUID,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=CREATE_RATE_LIMIT_MAX,
            window_seconds=CREATE_RATE_LIMIT_WINDOW,
        )
    ),
) -> None:
    """Delete a project owned by the authenticated Pro user.

    When a project is deleted, associated chats will have their
    project_id set to NULL (ON DELETE SET NULL in database schema).

    Args:
        project_id: The UUID of the project to delete.
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        None (204 No Content on success).

    Raises:
        HTTPException: On auth errors (401), non-pro plan (403),
            project not found (404), or rate limit errors (429).
    """
    _check_pro_plan(current_user)

    user_id = current_user.get("user_id", "unknown")
    logger.info(
        "Deleting project=%s for user=%s",
        project_id,
        user_id,
    )

    # Placeholder: Fetch project from database to verify existence and ownership
    # project = await supabase.table("projects") \
    #     .select("*") \
    #     .eq("id", str(project_id)) \
    #     .single() \
    #     .execute()

    # TODO: Replace with actual Supabase query once the database client is wired.
    # This placeholder always returns None, making the endpoint always 404.
    # The code below (ownership check, delete operation) will become
    # reachable once this line returns real query results.
    # Placeholder: Simulate project not found check
    project_data: dict[str, Any] | None = None  # Would come from DB query

    if project_data is None:
        raise HTTPException(
            status_code=404,
            detail="Project not found.",
        )

    _check_project_ownership(project_data.get("user_id", ""), user_id)

    # Placeholder: Delete project from database via Supabase client
    # Chats with this project_id will have project_id set to NULL (DB constraint)
    # await supabase.table("projects") \
    #     .delete() \
    #     .eq("id", str(project_id)) \
    #     .execute()

    logger.info("Project=%s deleted successfully", project_id)


@router.get(
    "/{project_id}/chats",
    response_model=ProjectChatsResponse,
    summary="List chats in a project",
)
async def list_project_chats(
    project_id: UUID,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=LIST_RATE_LIMIT_MAX,
            window_seconds=LIST_RATE_LIMIT_WINDOW,
        )
    ),
) -> ProjectChatsResponse:
    """List all chats belonging to a project.

    Returns chats ordered by updated_at descending (most recently
    active first). The user must own the project to view its chats.

    Args:
        project_id: The UUID of the project.
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        ProjectChatsResponse containing a list of chats in the project.

    Raises:
        HTTPException: On auth errors (401), non-pro plan (403),
            project not found (404), or rate limit errors (429).
    """
    _check_pro_plan(current_user)

    user_id = current_user.get("user_id", "unknown")
    logger.info(
        "Listing chats for project=%s, user=%s",
        project_id,
        user_id,
    )

    # Placeholder: Fetch project from database to verify existence and ownership
    # project = await supabase.table("projects") \
    #     .select("*") \
    #     .eq("id", str(project_id)) \
    #     .single() \
    #     .execute()

    # Placeholder: Simulate project not found check
    project_data: dict[str, Any] | None = None  # Would come from DB query

    if project_data is None:
        raise HTTPException(
            status_code=404,
            detail="Project not found.",
        )

    _check_project_ownership(project_data.get("user_id", ""), user_id)

    # Placeholder: Query chats table via Supabase client
    # chats = await supabase.table("chats") \
    #     .select("id, title, updated_at") \
    #     .eq("project_id", str(project_id)) \
    #     .order("updated_at", desc=True) \
    #     .execute()

    # Placeholder response until database is connected
    return ProjectChatsResponse(chats=[])

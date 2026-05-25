"""Export router - handles chat export to Markdown and PDF."""

import logging

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.export_service import export_service

logger = logging.getLogger(__name__)

router = APIRouter()


async def _get_user_plan(supabase, user_id: str) -> str:
    """Get user's current plan from subscriptions table."""
    try:
        result = (
            supabase.table("subscriptions")
            .select("plan")
            .eq("user_id", user_id)
            .execute()
        )
        if result.data:
            return result.data[0]["plan"]
        return "free"
    except Exception as e:
        logger.error(f"Error getting user plan: {str(e)}")
        return "free"


@router.get("/chat/{chat_id}/markdown")
async def export_chat_markdown(
    chat_id: str,
    current_user: dict = Depends(get_current_user),
) -> Response:
    """Export a single chat as Markdown file."""
    user_id = current_user["id"]
    supabase = get_supabase_client()

    # Verify chat belongs to user
    chat_result = (
        supabase.table("chats")
        .select("*")
        .eq("id", chat_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not chat_result.data:
        raise HTTPException(status_code=404, detail="Chat not found")

    chat = chat_result.data[0]

    # Get messages ordered by created_at
    messages_result = (
        supabase.table("messages")
        .select("*")
        .eq("chat_id", chat_id)
        .order("created_at", desc=False)
        .execute()
    )
    messages = messages_result.data if messages_result.data else []

    markdown_content = export_service.export_as_markdown(chat, messages)

    title = chat.get("title", "chat")
    filename = f"{title}.md".replace(" ", "_")

    return Response(
        content=markdown_content,
        media_type="text/markdown",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )


@router.get("/chat/{chat_id}/pdf")
async def export_chat_pdf(
    chat_id: str,
    current_user: dict = Depends(get_current_user),
) -> Response:
    """Export a single chat as PDF. Requires basic or pro plan."""
    user_id = current_user["id"]
    supabase = get_supabase_client()

    # Check plan - free users cannot export PDF
    plan = await _get_user_plan(supabase, user_id)
    if plan == "free":
        raise HTTPException(
            status_code=403,
            detail="Upgrade to export as PDF",
        )

    # Verify chat belongs to user
    chat_result = (
        supabase.table("chats")
        .select("*")
        .eq("id", chat_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not chat_result.data:
        raise HTTPException(status_code=404, detail="Chat not found")

    chat = chat_result.data[0]

    # Get messages ordered by created_at
    messages_result = (
        supabase.table("messages")
        .select("*")
        .eq("chat_id", chat_id)
        .order("created_at", desc=False)
        .execute()
    )
    messages = messages_result.data if messages_result.data else []

    pdf_bytes = export_service.export_as_pdf(chat, messages)

    title = chat.get("title", "chat")
    filename = f"{title}.pdf".replace(" ", "_")

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )


@router.get("/all/markdown")
async def export_all_markdown(
    current_user: dict = Depends(get_current_user),
) -> Response:
    """Export all chats as a single Markdown file. Pro plan only."""
    user_id = current_user["id"]
    supabase = get_supabase_client()

    # Pro plan only
    plan = await _get_user_plan(supabase, user_id)
    if plan != "pro":
        raise HTTPException(
            status_code=403,
            detail="Upgrade to Pro to export all chats",
        )

    # Get all user chats
    chats_result = (
        supabase.table("chats")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=False)
        .execute()
    )
    chats = chats_result.data if chats_result.data else []

    if not chats:
        raise HTTPException(status_code=404, detail="No chats found")

    # Build combined markdown
    all_markdown_parts = []
    for chat in chats:
        messages_result = (
            supabase.table("messages")
            .select("*")
            .eq("chat_id", chat["id"])
            .order("created_at", desc=False)
            .execute()
        )
        messages = messages_result.data if messages_result.data else []
        part = export_service.export_as_markdown(chat, messages)
        all_markdown_parts.append(part)

    combined_markdown = "\n\n---\n\n".join(all_markdown_parts)

    return Response(
        content=combined_markdown,
        media_type="text/markdown",
        headers={
            "Content-Disposition": 'attachment; filename="mio_all_chats.md"',
        },
    )

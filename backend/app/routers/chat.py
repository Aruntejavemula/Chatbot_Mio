"""Chat router - handles chat CRUD and message streaming."""

import json
import logging
from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from supabase import Client

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.middleware.security_middleware import security_middleware
from app.models.chat import ChatCreate, ChatResponse, ChatUpdate, MessageCreate, MessageResponse
from app.routers.keys import get_decrypted_key
from app.services.ai_service import AIService
from app.services.encryption_service import EncryptionService
from app.utils.constants import SUPPORTED_PROVIDERS
from app.utils.helpers import check_token_abuse, circuit_breaker

logger = logging.getLogger(__name__)

router = APIRouter()

ai_service = AIService()
encryption_service = EncryptionService()

# Cost rates per token (input_cost, output_cost) in USD
COST_RATES = {
    "deepseek-chat": {"input": 0.00000014, "output": 0.00000028},
    "deepseek-reasoner": {"input": 0.00000055, "output": 0.0000022},
    "moonshot-v1-8k": {"input": 0.000001, "output": 0.000001},
    "gemini-2.5-flash": {"input": 0.00000015, "output": 0.0000006},
    "gpt-4o-mini": {"input": 0.00000015, "output": 0.0000006},
    "gpt-4o": {"input": 0.0000025, "output": 0.00001},
    "claude-haiku-4-5-20251001": {"input": 0.0000008, "output": 0.000004},
    "claude-sonnet-4-5": {"input": 0.000003, "output": 0.000015},
}

# Context window sizes per model
MODEL_CONTEXT_LIMITS = {
    "gpt-4o": 128000,
    "gpt-4o-mini": 128000,
    "claude-sonnet-4-5": 200000,
    "claude-haiku-4-5-20251001": 200000,
    "deepseek-chat": 64000,
    "deepseek-reasoner": 64000,
    "gemini-2.5-pro": 1000000,
    "gemini-2.5-flash": 1000000,
    "moonshot-v1-8k": 8000,
    "moonshot-v1-32k": 32000,
    "moonshot-v1-128k": 128000,
}


class MakePromptRequest(BaseModel):
    """Request model for prompt maker."""
    rough_text: str = Field(..., description="User's rough message to improve")
    provider: str = Field(..., description="BYOK provider to use")
    model: str = Field(..., description="Model to use for prompt improvement")


PROMPT_MAKER_SYSTEM = (
    "You are an expert prompt engineer. "
    "Convert the user's rough message into a clear, specific, effective AI prompt. "
    "Keep the original intent exactly. "
    "Make it detailed and unambiguous. "
    "Return ONLY the improved prompt. "
    "No explanation. No preamble. "
    "No 'Here is your prompt:' prefix. "
    "Just the prompt itself."
)


@router.get("/providers")
async def get_providers() -> list[dict]:
    """Get list of supported AI providers and their models. No auth required."""
    return SUPPORTED_PROVIDERS


@router.post("/make-prompt")
async def make_prompt(
    body: MakePromptRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Convert rough text into an effective AI prompt using user's own API key.
    Uses BYOK only - zero cost to platform.
    """
    user_id = current_user["id"]

    if not body.rough_text or not body.rough_text.strip():
        raise HTTPException(status_code=400, detail="rough_text is required")
    if len(body.rough_text) > 2000:
        raise HTTPException(status_code=400, detail="rough_text must be under 2000 characters")
    if not body.provider:
        raise HTTPException(status_code=400, detail="provider is required")
    if not body.model:
        raise HTTPException(status_code=400, detail="model is required")

    supabase = get_supabase_client()
    try:
        api_key = await get_decrypted_key(user_id, body.provider, supabase)
    except HTTPException:
        raise HTTPException(
            status_code=400,
            detail=f"Add your API key for {body.provider} to use Prompt Maker",
        )

    messages = [
        {"role": "system", "content": PROMPT_MAKER_SYSTEM},
        {"role": "user", "content": body.rough_text},
    ]

    try:
        full_response = ""
        tokens_used = 0

        async for chunk in ai_service.stream_response(
            provider=body.provider,
            model=body.model,
            messages=messages,
            api_key=api_key,
            zero_fluff=False,
            max_tokens=500,
        ):
            if chunk.startswith("data: "):
                try:
                    data = json.loads(chunk[6:])
                    if data.get("type") == "text":
                        full_response += data.get("content", "")
                    elif data.get("type") == "done":
                        tokens_data = data.get("tokens", {})
                        tokens_used = tokens_data.get("input", 0) + tokens_data.get("output", 0)
                    elif data.get("type") == "error":
                        raise HTTPException(
                            status_code=502,
                            detail=data.get("error", "AI provider error"),
                        )
                except json.JSONDecodeError:
                    continue

        if not full_response:
            raise HTTPException(status_code=502, detail="No response from AI provider")

        logger.info(f"Prompt maker used by {user_id}: {tokens_used} tokens")

        return {
            "improved_prompt": full_response.strip(),
            "original": body.rough_text,
            "tokens_used": tokens_used,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prompt maker error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to generate improved prompt")


STORAGE_TYPE_BY_PLAN = {
    "free": "local",
    "basic": "drive",
    "pro": "cloud",
}

DAILY_MESSAGE_LIMITS = {
    "free": 20,
    "basic": 100,
    "pro": -1,  # unlimited
}


async def _get_user_plan(supabase: Client, user_id: str) -> str:
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


async def _check_message_limit(supabase: Client, user_id: str, plan: str) -> None:
    """Check if user has exceeded daily message limit."""
    limit = DAILY_MESSAGE_LIMITS.get(plan, 20)
    if limit == -1:
        return  # Unlimited

    today = date.today().isoformat()
    try:
        result = (
            supabase.table("messages")
            .select("id", count="exact")
            .eq("chat_id", f"user_{user_id}")
            .gte("created_at", f"{today}T00:00:00")
            .execute()
        )
        # Count messages by joining through chats
        chats_result = (
            supabase.table("chats")
            .select("id")
            .eq("user_id", user_id)
            .execute()
        )
        if not chats_result.data:
            return

        chat_ids = [c["id"] for c in chats_result.data]
        count = 0
        for chat_id in chat_ids:
            msg_result = (
                supabase.table("messages")
                .select("id", count="exact")
                .eq("chat_id", chat_id)
                .eq("role", "user")
                .gte("created_at", f"{today}T00:00:00")
                .execute()
            )
            count += len(msg_result.data) if msg_result.data else 0

        if count >= limit:
            raise HTTPException(
                status_code=429,
                detail=f"Daily limit reached ({limit} messages). Upgrade to continue.",
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking message limit: {str(e)}")


async def _get_api_key(supabase: Client, user_id: str, provider: str) -> str:
    """Get and decrypt user's API key for a provider."""
    try:
        result = (
            supabase.table("api_keys")
            .select("encrypted_key, iv")
            .eq("user_id", user_id)
            .eq("provider", provider.lower())
            .execute()
        )
        if not result.data:
            raise HTTPException(
                status_code=400,
                detail=f"No API key found for {provider}. Add one in settings.",
            )
        key_data = result.data[0]
        decrypted = encryption_service.decrypt(
            key_data["encrypted_key"], key_data["iv"]
        )
        return decrypted
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting API key: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve API key")


@router.post("/stream")
async def stream_message(
    request: Request,
    body: MessageCreate,
    current_user: dict = Depends(get_current_user),
) -> StreamingResponse:
    """
    Stream AI response for a chat message.

    Validates limits, gets API key, saves messages, streams response.
    """
    user_id = current_user["id"]

    # Security checks
    await security_middleware.check_account_suspended(user_id)
    security_middleware.verify_request_headers(request)
    await security_middleware.check_message_repetition(user_id, body.content)
    await security_middleware.check_load()

    # Check circuit breaker for provider
    if await circuit_breaker.is_open(body.provider):
        raise HTTPException(
            status_code=503,
            detail="Provider temporarily unavailable. Try another model.",
        )

    if not body.content or not body.content.strip():
        raise HTTPException(status_code=400, detail="Message content is required")
    if len(body.content) > 10000:
        raise HTTPException(status_code=400, detail="Message too long (max 10000 characters)")
    if not body.model:
        raise HTTPException(status_code=400, detail="Model is required")
    if not body.provider:
        raise HTTPException(status_code=400, detail="Provider is required")

    supabase = get_supabase_client()

    # Get plan and check limits
    plan = await _get_user_plan(supabase, user_id)
    await _check_message_limit(supabase, user_id, plan)

    # Get API key
    api_key = await _get_api_key(supabase, user_id, body.provider)

    # Save user message
    try:
        supabase.table("messages").insert({
            "chat_id": body.chat_id,
            "role": "user",
            "content": body.content,
        }).execute()

        preview = body.content[:100]
        supabase.table("chats").update({
            "last_preview": preview,
            "message_count": supabase.table("chats").select("message_count").eq("id", body.chat_id).execute().data[0]["message_count"] + 1,
        }).eq("id", body.chat_id).execute()
    except Exception as e:
        logger.error(f"Error saving user message: {str(e)}")

    # Get chat history (last 20 messages)
    try:
        history_result = (
            supabase.table("messages")
            .select("role, content")
            .eq("chat_id", body.chat_id)
            .order("created_at", desc=False)
            .limit(20)
            .execute()
        )
        messages = history_result.data if history_result.data else []
    except Exception as e:
        logger.error(f"Error fetching history: {str(e)}")
        messages = [{"role": "user", "content": body.content}]

    # Get zero_fluff setting
    try:
        settings_result = (
            supabase.table("settings")
            .select("zero_fluff_on")
            .eq("user_id", user_id)
            .execute()
        )
        zero_fluff = settings_result.data[0]["zero_fluff_on"] if settings_result.data else True
    except Exception:
        zero_fluff = True

    # Stream response
    async def generate():
        full_response = ""
        tokens_data = {"input": 0, "output": 0}

        async for chunk in ai_service.stream_response(
            provider=body.provider,
            model=body.model,
            messages=messages,
            api_key=api_key,
            zero_fluff=zero_fluff,
        ):
            yield chunk
            # Parse chunk to accumulate response
            if chunk.startswith("data: "):
                try:
                    data = json.loads(chunk[6:])
                    if data.get("type") == "text":
                        full_response += data.get("content", "")
                    elif data.get("type") == "done":
                        tokens_data = data.get("tokens", tokens_data)
                except json.JSONDecodeError:
                    pass

        # Save AI response after streaming completes
        try:
            supabase.table("messages").insert({
                "chat_id": body.chat_id,
                "role": "assistant",
                "content": full_response,
                "tokens_input": tokens_data["input"],
                "tokens_output": tokens_data["output"],
                "model": body.model,
            }).execute()

            # Update token usage
            today_str = date.today().isoformat()
            month_str = datetime.now().strftime("%Y-%m")
            existing = (
                supabase.table("token_usage")
                .select("*")
                .eq("user_id", user_id)
                .eq("date", today_str)
                .execute()
            )
            if existing.data:
                supabase.table("token_usage").update({
                    "tokens_used_input": existing.data[0]["tokens_used_input"] + tokens_data["input"],
                    "tokens_used_output": existing.data[0]["tokens_used_output"] + tokens_data["output"],
                    "model_used": body.model,
                }).eq("user_id", user_id).eq("date", today_str).execute()
            else:
                supabase.table("token_usage").insert({
                    "user_id": user_id,
                    "date": today_str,
                    "month": month_str,
                    "tokens_used_input": tokens_data["input"],
                    "tokens_used_output": tokens_data["output"],
                    "model_used": body.model,
                }).execute()

            # Increment loading word index
            settings_result = (
                supabase.table("settings")
                .select("loading_word_index")
                .eq("user_id", user_id)
                .execute()
            )
            if settings_result.data:
                current_index = settings_result.data[0]["loading_word_index"]
                supabase.table("settings").update({
                    "loading_word_index": (current_index + 1) % 40,
                }).eq("user_id", user_id).execute()

        except Exception as e:
            logger.error(f"Error saving AI response: {str(e)}")

        # Check for token abuse
        total_tokens = tokens_data["input"] + tokens_data["output"]
        if total_tokens > 0:
            redis = await security_middleware._get_redis()
            await check_token_abuse(user_id, total_tokens, redis)

        await security_middleware.decrement_active_streams()

    await security_middleware.increment_active_streams()

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/chats")
async def get_chats(current_user: dict = Depends(get_current_user)) -> list[dict]:
    """Get all chats for current user, ordered by most recent."""
    try:
        supabase = get_supabase_client()
        result = (
            supabase.table("chats")
            .select("*")
            .eq("user_id", current_user["id"])
            .order("updated_at", desc=True)
            .execute()
        )
        return result.data if result.data else []
    except Exception as e:
        logger.error(f"Error fetching chats: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch chats")


@router.post("/chats")
async def create_chat(
    body: ChatCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Create a new chat."""
    try:
        supabase = get_supabase_client()
        user_id = current_user["id"]

        plan = await _get_user_plan(supabase, user_id)
        storage_type = STORAGE_TYPE_BY_PLAN.get(plan, "local")

        result = (
            supabase.table("chats")
            .insert({
                "user_id": user_id,
                "title": "New Chat",
                "model": body.model,
                "provider": body.provider,
                "storage_type": storage_type,
            })
            .execute()
        )
        logger.info(f"Created chat for user: {user_id}")
        return result.data[0]
    except Exception as e:
        logger.error(f"Error creating chat: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create chat")


@router.delete("/chats/{chat_id}")
async def delete_chat(
    chat_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Delete a chat and all its messages."""
    try:
        supabase = get_supabase_client()
        user_id = current_user["id"]

        # Verify ownership
        result = (
            supabase.table("chats")
            .select("id")
            .eq("id", chat_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Chat not found")

        # Delete (cascade deletes messages)
        supabase.table("chats").delete().eq("id", chat_id).execute()
        logger.info(f"Deleted chat {chat_id} for user {user_id}")
        return {"message": "Chat deleted"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting chat: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete chat")


@router.patch("/chats/{chat_id}")
async def update_chat(
    chat_id: str,
    body: ChatUpdate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Update chat title."""
    try:
        supabase = get_supabase_client()
        user_id = current_user["id"]

        # Verify ownership
        result = (
            supabase.table("chats")
            .select("id")
            .eq("id", chat_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Chat not found")

        update_data = {}
        if body.title is not None:
            update_data["title"] = body.title

        if update_data:
            updated = (
                supabase.table("chats")
                .update(update_data)
                .eq("id", chat_id)
                .execute()
            )
            return updated.data[0]
        return result.data[0]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating chat: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update chat")


@router.get("/chats/{chat_id}/messages")
async def get_messages(
    chat_id: str,
    current_user: dict = Depends(get_current_user),
) -> list[dict]:
    """Get all messages for a chat."""
    try:
        supabase = get_supabase_client()
        user_id = current_user["id"]

        # Verify chat ownership
        chat_result = (
            supabase.table("chats")
            .select("id")
            .eq("id", chat_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not chat_result.data:
            raise HTTPException(status_code=404, detail="Chat not found")

        result = (
            supabase.table("messages")
            .select("*")
            .eq("chat_id", chat_id)
            .order("created_at", desc=False)
            .execute()
        )
        return result.data if result.data else []
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching messages: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch messages")

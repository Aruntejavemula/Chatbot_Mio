"""Mio API application entry point."""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import projects, voice

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Mio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(voice.router, prefix="/voice", tags=["voice"])
app.include_router(projects.router, prefix="/projects", tags=["projects"])


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


logger.info("Mio API initialized")

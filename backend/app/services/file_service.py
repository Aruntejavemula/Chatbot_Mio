"""File service - processes uploaded files for AI consumption."""

import base64
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

SUPPORTED_TYPES = {
    # Images
    ".png": "image",
    ".jpg": "image",
    ".jpeg": "image",
    ".gif": "image",
    ".webp": "image",
    # Documents
    ".pdf": "document",
    ".docx": "document",
    ".txt": "document",
    # Code / text
    ".py": "text",
    ".js": "text",
    ".ts": "text",
    ".jsx": "text",
    ".tsx": "text",
    ".html": "text",
    ".css": "text",
    ".json": "text",
    ".yaml": "text",
    ".yml": "text",
    ".md": "text",
    ".csv": "text",
    ".xml": "text",
    ".sql": "text",
    ".sh": "text",
    ".dart": "text",
    ".java": "text",
    ".kt": "text",
    ".swift": "text",
    ".go": "text",
    ".rs": "text",
    ".cpp": "text",
    ".c": "text",
    ".h": "text",
    ".rb": "text",
    ".php": "text",
}

LANGUAGE_MAP = {
    ".py": "python",
    ".js": "javascript",
    ".ts": "typescript",
    ".jsx": "jsx",
    ".tsx": "tsx",
    ".html": "html",
    ".css": "css",
    ".json": "json",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".md": "markdown",
    ".csv": "csv",
    ".xml": "xml",
    ".sql": "sql",
    ".sh": "bash",
    ".dart": "dart",
    ".java": "java",
    ".kt": "kotlin",
    ".swift": "swift",
    ".go": "go",
    ".rs": "rust",
    ".cpp": "cpp",
    ".c": "c",
    ".h": "c",
    ".rb": "ruby",
    ".php": "php",
}


class FileService:
    """Processes uploaded files into AI-ready content."""

    def process_file(self, filename: str, content: bytes) -> dict:
        """Process an uploaded file and return structured content for AI."""
        file_type = self._get_file_type(filename)

        if file_type == "image":
            return self._process_image(filename, content)
        elif file_type == "document":
            return self._process_document(filename, content)
        elif file_type == "text":
            return self._process_text_file(filename, content)
        else:
            raise ValueError(f"Unsupported file type: {filename}")

    def _get_file_type(self, filename: str) -> Optional[str]:
        """Determine file type category from extension."""
        ext = Path(filename).suffix.lower()
        return SUPPORTED_TYPES.get(ext)

    def _process_image(self, filename: str, content: bytes) -> dict:
        """Encode image to base64 for AI vision models."""
        ext = Path(filename).suffix.lower()
        mime_map = {
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif": "image/gif",
            ".webp": "image/webp",
        }
        mime_type = mime_map.get(ext, "image/png")
        encoded = base64.b64encode(content).decode("utf-8")
        data_url = f"data:{mime_type};base64,{encoded}"

        return {
            "type": "image",
            "mime_type": mime_type,
            "content": data_url,
            "description": f"Image file: {filename}",
        }

    def _process_document(self, filename: str, content: bytes) -> dict:
        """Extract text from PDF, DOCX, or TXT files."""
        ext = Path(filename).suffix.lower()
        text = ""

        if ext == ".pdf":
            try:
                from pypdf import PdfReader
                import io

                reader = PdfReader(io.BytesIO(content))
                pages = []
                for page in reader.pages:
                    page_text = page.extract_text()
                    if page_text:
                        pages.append(page_text)
                text = "\n\n".join(pages)
            except Exception as e:
                logger.error(f"Error processing PDF {filename}: {e}")
                text = f"[Error extracting PDF content: {str(e)}]"

        elif ext == ".docx":
            try:
                from docx import Document
                import io

                doc = Document(io.BytesIO(content))
                paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
                text = "\n\n".join(paragraphs)
            except Exception as e:
                logger.error(f"Error processing DOCX {filename}: {e}")
                text = f"[Error extracting DOCX content: {str(e)}]"

        elif ext == ".txt":
            try:
                text = content.decode("utf-8")
            except UnicodeDecodeError:
                text = content.decode("latin-1")

        # Truncate at 50K characters
        if len(text) > 50000:
            text = text[:50000] + "\n\n[Content truncated at 50,000 characters]"

        return {
            "type": "document",
            "format": ext.lstrip("."),
            "content": text,
            "char_count": len(text),
            "description": f"Document: {filename}",
        }

    def _process_text_file(self, filename: str, content: bytes) -> dict:
        """Process code and data files with language detection."""
        ext = Path(filename).suffix.lower()
        language = LANGUAGE_MAP.get(ext, "text")

        try:
            text = content.decode("utf-8")
        except UnicodeDecodeError:
            text = content.decode("latin-1")

        # Truncate at 50K characters
        if len(text) > 50000:
            text = text[:50000] + "\n\n[Content truncated at 50,000 characters]"

        return {
            "type": "text",
            "language": language,
            "content": text,
            "char_count": len(text),
            "description": f"{language.capitalize()} file: {filename}",
        }


# Module-level instance
file_service = FileService()

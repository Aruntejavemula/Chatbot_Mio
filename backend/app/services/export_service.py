"""Export service - converts chat data to Markdown and PDF formats."""

import html
import io
from datetime import datetime
from typing import Optional

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.colors import HexColor
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    HRFlowable,
)


class ExportService:
    """Handles exporting chat conversations to various formats."""

    def export_as_markdown(self, chat: dict, messages: list[dict]) -> str:
        """
        Convert a chat and its messages to a formatted Markdown string.

        Args:
            chat: Chat metadata dict with title, model, created_at, etc.
            messages: List of message dicts with role, content, created_at.

        Returns:
            Formatted markdown string.
        """
        title = chat.get("title", "Untitled Chat")
        model = chat.get("model", "Unknown")
        created_at = chat.get("created_at", "")
        lines = []

        # Header
        lines.append(f"# {title}")
        lines.append("")
        lines.append(f"**Model:** {model}")
        if created_at:
            lines.append(f"**Created:** {created_at}")
        lines.append("")
        lines.append("---")
        lines.append("")

        # Messages
        for msg in messages:
            role = msg.get("role", "unknown")
            content = msg.get("content", "")
            timestamp = msg.get("created_at", "")

            if role == "user":
                lines.append(f"### You")
            else:
                lines.append(f"### Mio")

            if timestamp:
                lines.append(f"*{timestamp}*")
            lines.append("")
            lines.append(content)
            lines.append("")
            lines.append("---")
            lines.append("")

        # Footer
        lines.append("*Exported from Mio*")

        return "\n".join(lines)

    def export_as_pdf(self, chat: dict, messages: list[dict]) -> bytes:
        """
        Generate an A4 PDF of the chat conversation.

        Colors:
            - Title: Persian Orange #CC5801
            - Meta info: #6B6B6B
            - User labels: #CC5801
            - AI labels: #1A1A1A
            - Body text: #1A1A1A 11px
            - HR dividers: #E0DDD8

        Args:
            chat: Chat metadata dict.
            messages: List of message dicts.

        Returns:
            PDF content as bytes.
        """
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=20 * mm,
            leftMargin=20 * mm,
            topMargin=20 * mm,
            bottomMargin=20 * mm,
        )

        # Define styles
        title_style = ParagraphStyle(
            "ChatTitle",
            fontSize=18,
            leading=22,
            textColor=HexColor("#CC5801"),
            spaceAfter=6,
        )

        meta_style = ParagraphStyle(
            "MetaInfo",
            fontSize=10,
            leading=12,
            textColor=HexColor("#6B6B6B"),
            spaceAfter=4,
        )

        user_label_style = ParagraphStyle(
            "UserLabel",
            fontSize=12,
            leading=14,
            textColor=HexColor("#CC5801"),
            spaceBefore=8,
            spaceAfter=2,
        )

        ai_label_style = ParagraphStyle(
            "AILabel",
            fontSize=12,
            leading=14,
            textColor=HexColor("#1A1A1A"),
            spaceBefore=8,
            spaceAfter=2,
        )

        body_style = ParagraphStyle(
            "BodyText",
            fontSize=11,
            leading=14,
            textColor=HexColor("#1A1A1A"),
            spaceAfter=6,
        )

        elements = []

        # Title
        title = html.escape(chat.get("title", "Untitled Chat"))
        elements.append(Paragraph(title, title_style))

        # Meta info
        model = html.escape(chat.get("model", "Unknown"))
        elements.append(Paragraph(f"Model: {model}", meta_style))

        created_at = chat.get("created_at", "")
        if created_at:
            elements.append(Paragraph(f"Created: {html.escape(created_at)}", meta_style))

        elements.append(Spacer(1, 10))
        elements.append(
            HRFlowable(
                width="100%",
                thickness=1,
                color=HexColor("#E0DDD8"),
                spaceAfter=10,
            )
        )

        # Messages
        for msg in messages:
            role = msg.get("role", "unknown")
            content = msg.get("content", "")
            timestamp = msg.get("created_at", "")

            # Label
            if role == "user":
                elements.append(Paragraph("You", user_label_style))
            else:
                elements.append(Paragraph("Mio", ai_label_style))

            # Timestamp
            if timestamp:
                elements.append(Paragraph(html.escape(timestamp), meta_style))

            # Body content - escape HTML and preserve newlines
            escaped_content = html.escape(content)
            escaped_content = escaped_content.replace("\n", "<br/>")
            elements.append(Paragraph(escaped_content, body_style))

            # Divider
            elements.append(Spacer(1, 6))
            elements.append(
                HRFlowable(
                    width="100%",
                    thickness=0.5,
                    color=HexColor("#E0DDD8"),
                    spaceAfter=6,
                )
            )

        # Footer
        footer_style = ParagraphStyle(
            "Footer",
            fontSize=9,
            leading=11,
            textColor=HexColor("#6B6B6B"),
            spaceBefore=12,
        )
        elements.append(Paragraph("Exported from Mio", footer_style))

        doc.build(elements)
        pdf_bytes = buffer.getvalue()
        buffer.close()
        return pdf_bytes


export_service = ExportService()

"""Search service - web search and deep research capabilities."""

import json
import logging
import re
from typing import AsyncGenerator, Optional

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)


class SearchService:
    """Handles web search and deep research operations."""

    def __init__(self):
        self.settings = get_settings()
        self.timeout = httpx.Timeout(15.0)

    async def web_search(self, query: str, num_results: int = 5) -> list[dict]:
        """
        Search the web using Brave Search API with DuckDuckGo fallback.

        Returns list of search results with title, url, and snippet.
        """
        if self.settings.BRAVE_SEARCH_API_KEY:
            try:
                results = await self._brave_search(query, num_results)
                if results:
                    return results
            except Exception as e:
                logger.warning(f"Brave Search failed, falling back to DuckDuckGo: {e}")

        return await self._duckduckgo_search(query, num_results)

    async def _brave_search(self, query: str, num_results: int = 5) -> list[dict]:
        """Search using Brave Search API."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                "https://api.search.brave.com/res/v1/web/search",
                params={"q": query, "count": num_results},
                headers={
                    "Accept": "application/json",
                    "Accept-Encoding": "gzip",
                    "X-Subscription-Token": self.settings.BRAVE_SEARCH_API_KEY,
                },
            )
            response.raise_for_status()
            data = response.json()

            results = []
            for item in data.get("web", {}).get("results", [])[:num_results]:
                results.append({
                    "title": item.get("title", ""),
                    "url": item.get("url", ""),
                    "snippet": item.get("description", ""),
                })
            return results

    async def _duckduckgo_search(self, query: str, num_results: int = 5) -> list[dict]:
        """Fallback search using DuckDuckGo HTML."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                "https://html.duckduckgo.com/html/",
                params={"q": query},
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                },
            )
            response.raise_for_status()
            html = response.text

            results = []
            # Parse DuckDuckGo HTML results
            result_blocks = re.findall(
                r'<a rel="nofollow" class="result__a" href="(.*?)">(.*?)</a>.*?'
                r'<a class="result__snippet".*?>(.*?)</a>',
                html,
                re.DOTALL,
            )

            for url, title, snippet in result_blocks[:num_results]:
                clean_title = re.sub(r"<.*?>", "", title).strip()
                clean_snippet = re.sub(r"<.*?>", "", snippet).strip()
                results.append({
                    "title": clean_title,
                    "url": url,
                    "snippet": clean_snippet,
                })

            return results

    async def fetch_page_content(self, url: str, max_length: int = 5000) -> str:
        """
        Fetch a web page and return clean text content.

        Strips HTML tags, scripts, styles, and returns plain text.
        """
        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                response = await client.get(
                    url,
                    headers={
                        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    },
                )
                response.raise_for_status()
                html = response.text

            # Remove script and style elements
            html = re.sub(r"<script[^>]*>.*?</script>", "", html, flags=re.DOTALL)
            html = re.sub(r"<style[^>]*>.*?</style>", "", html, flags=re.DOTALL)
            # Remove HTML comments
            html = re.sub(r"<!--.*?-->", "", html, flags=re.DOTALL)
            # Remove tags
            text = re.sub(r"<[^>]+>", " ", html)
            # Clean whitespace
            text = re.sub(r"\s+", " ", text).strip()
            # Decode HTML entities
            text = re.sub(r"&amp;", "&", text)
            text = re.sub(r"&lt;", "<", text)
            text = re.sub(r"&gt;", ">", text)
            text = re.sub(r"&quot;", '"', text)
            text = re.sub(r"&#39;", "'", text)
            text = re.sub(r"&nbsp;", " ", text)

            return text[:max_length]
        except Exception as e:
            logger.warning(f"Failed to fetch page content from {url}: {e}")
            return ""

    async def deep_research(
        self, query: str, num_searches: int = 3
    ) -> AsyncGenerator[str, None]:
        """
        Perform deep research on a topic.

        Async generator that yields progress updates through stages:
        - searching: Finding relevant sources
        - processing: Extracting and analyzing content
        - synthesizing: Combining findings into a report

        Yields JSON strings with stage and content info.
        """
        # Stage 1: Generate sub-questions
        yield json.dumps({
            "stage": "searching",
            "message": "Generating research questions...",
        })

        sub_questions = self._generate_sub_questions(query, num_searches)

        # Stage 2: Search for each sub-question
        all_results = []
        for i, question in enumerate(sub_questions):
            yield json.dumps({
                "stage": "searching",
                "message": f"Searching ({i + 1}/{len(sub_questions)}): {question}",
            })

            results = await self.web_search(question, num_results=3)
            all_results.extend(results)

        # Stage 3: Fetch and process page content
        yield json.dumps({
            "stage": "processing",
            "message": f"Processing {len(all_results)} sources...",
        })

        contents = []
        for i, result in enumerate(all_results):
            yield json.dumps({
                "stage": "processing",
                "message": f"Reading source ({i + 1}/{len(all_results)}): {result.get('title', 'Unknown')}",
            })

            content = await self.fetch_page_content(result["url"], max_length=3000)
            if content:
                contents.append({
                    "title": result.get("title", ""),
                    "url": result.get("url", ""),
                    "content": content,
                })

        # Stage 4: Synthesize
        yield json.dumps({
            "stage": "synthesizing",
            "message": "Synthesizing research findings...",
        })

        report = self._synthesize_research(query, contents)

        yield json.dumps({
            "stage": "complete",
            "message": "Research complete",
            "report": report,
            "sources": [{"title": c["title"], "url": c["url"]} for c in contents],
        })

    def _generate_sub_questions(self, query: str, num_questions: int = 3) -> list[str]:
        """
        Generate sub-questions to research a topic thoroughly.

        Breaks main query into focused research angles.
        """
        # Generate variations of the query for broader research
        questions = [query]

        if num_questions >= 2:
            questions.append(f"{query} explained overview")
        if num_questions >= 3:
            questions.append(f"{query} latest developments 2024")
        if num_questions >= 4:
            questions.append(f"{query} pros and cons analysis")
        if num_questions >= 5:
            questions.append(f"{query} examples use cases")

        return questions[:num_questions]

    def _synthesize_research(self, query: str, contents: list[dict]) -> str:
        """
        Synthesize research findings into a coherent report.

        Combines content from multiple sources into a structured summary.
        """
        if not contents:
            return f"No relevant information found for: {query}"

        # Build report from collected content
        report_parts = [f"# Research Report: {query}\n"]
        report_parts.append(f"Based on {len(contents)} sources:\n")

        for i, item in enumerate(contents, 1):
            title = item.get("title", "Unknown Source")
            content = item.get("content", "")
            url = item.get("url", "")

            # Take first 500 chars of each source as summary
            summary = content[:500]
            if len(content) > 500:
                summary += "..."

            report_parts.append(f"\n## Source {i}: {title}")
            report_parts.append(f"URL: {url}")
            report_parts.append(f"\n{summary}\n")

        report_parts.append("\n---")
        report_parts.append(
            f"\n*Research compiled from {len(contents)} sources for query: \"{query}\"*"
        )

        return "\n".join(report_parts)


# Module-level instance
search_service = SearchService()

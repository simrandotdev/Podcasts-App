"""A small async client for the Podcast Index API: https://podcastindex-org.github.io/docs-api/"""

import hashlib
import logging
import time
from collections.abc import Callable
from typing import Any

import httpx

from .config import Settings

logger = logging.getLogger(__name__)


class PodcastIndexError(Exception):
    """A failure to report to the caller, with the HTTP status the API responds with."""

    def __init__(self, status_code: int, message: str):
        super().__init__(message)
        self.status_code = status_code
        self.message = message


def auth_headers(api_key: str, api_secret: str, user_agent: str, now: float) -> dict[str, str]:
    """The headers Podcast Index requires on every request.

    `Authorization` is the SHA-1 of the key, the secret and the date, as lowercase hex. The date must be
    within 3 minutes of Podcast Index's clock.
    """
    date = str(int(now))
    digest = hashlib.sha1((api_key + api_secret + date).encode("utf-8")).hexdigest()
    return {"User-Agent": user_agent, "X-Auth-Key": api_key, "X-Auth-Date": date, "Authorization": digest}


class PodcastIndexClient:
    def __init__(self, http: httpx.AsyncClient, settings: Settings, clock: Callable[[], float] = time.time):
        self._http = http
        self._settings = settings
        self._clock = clock

    async def search_by_term(self, term: str, limit: int) -> list[dict[str, Any]]:
        """Feeds whose title, author or owner matches `term`."""
        data = await self._get("/search/byterm", {"q": term, "max": limit})
        return data.get("feeds") or []

    async def trending(self, limit: int, language: str | None = None,
                       category: str | None = None) -> list[dict[str, Any]]:
        """Feeds that are trending now, optionally limited to a language and categories."""
        params: dict[str, Any] = {"max": limit}
        if language:
            params["lang"] = language
        if category:
            params["cat"] = category
        data = await self._get("/podcasts/trending", params)
        return data.get("feeds") or []

    async def _get(self, path: str, params: dict[str, Any]) -> dict[str, Any]:
        settings = self._settings
        if not settings.has_credentials:
            raise PodcastIndexError(503, "The Podcast Index API key and secret aren't configured.")
        headers = auth_headers(settings.podcastindex_api_key, settings.podcastindex_api_secret,
                               settings.user_agent, self._clock())
        try:
            response = await self._http.get(settings.podcastindex_base_url + path, params=params, headers=headers)
        except httpx.TimeoutException:
            raise PodcastIndexError(504, "Podcast Index didn't respond in time.") from None
        except httpx.HTTPError as error:
            logger.warning("Podcast Index request to %s failed: %s", path, error)
            raise PodcastIndexError(502, "Couldn't reach Podcast Index.") from None

        if response.status_code in (401, 403):
            logger.warning("Podcast Index rejected the credentials (HTTP %s)", response.status_code)
            raise PodcastIndexError(502, "Podcast Index rejected the API credentials.")
        if response.status_code != 200:
            logger.warning("Podcast Index returned HTTP %s for %s", response.status_code, path)
            raise PodcastIndexError(502, f"Podcast Index returned HTTP {response.status_code}.")
        try:
            data = response.json()
        except ValueError:
            data = None
        if not isinstance(data, dict):
            raise PodcastIndexError(502, "Podcast Index returned an unreadable response.")
        # Podcast Index reports success as the string "true".
        if str(data.get("status")).lower() != "true":
            raise PodcastIndexError(502, data.get("description") or "Podcast Index couldn't complete the request.")
        return data

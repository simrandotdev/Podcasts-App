"""Responses in the shape of the iTunes Search API, so clients that decode iTunes results work unchanged."""

from datetime import UTC, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


class PodcastResult(BaseModel):
    """One podcast, with the fields of an iTunes Search API podcast result."""

    wrapperType: Literal["track"] = "track"
    kind: Literal["podcast"] = "podcast"
    collectionId: int = Field(description="The Podcast Index feed ID.")
    trackId: int = Field(description="The same as `collectionId`, as in iTunes results.")
    collectionName: str
    trackName: str
    artistName: str | None = None
    feedUrl: str = Field(description="The RSS feed URL, which identifies the podcast.")
    artworkUrl100: str | None = None
    artworkUrl600: str | None = None
    trackCount: int | None = Field(None, description="Episodes known to Podcast Index. Trending results omit it.")
    releaseDate: datetime | None = Field(None, description="When the newest episode was published.")
    genres: list[str] = Field(default_factory=list)
    itunesId: int | None = Field(None, description="The podcast's iTunes ID, when Podcast Index knows it.")


class SearchResponse(BaseModel):
    resultCount: int
    results: list[PodcastResult]


def podcast_result(feed: dict[str, Any]) -> PodcastResult | None:
    """Maps a Podcast Index feed to an iTunes-style result. Returns None for feeds that can't be played."""
    feed_url = (feed.get("url") or "").strip()
    feed_id = feed.get("id")
    if not feed_url or not isinstance(feed_id, int) or feed.get("dead"):
        return None
    title = feed.get("title") or ""
    artwork = feed.get("artwork") or feed.get("image") or None
    # Search results call it newestItemPubdate; trending results call it newestItemPublishTime.
    newest = feed.get("newestItemPubdate") or feed.get("newestItemPublishTime")
    categories = feed.get("categories")
    return PodcastResult(
        collectionId=feed_id,
        trackId=feed_id,
        collectionName=title,
        trackName=title,
        artistName=feed.get("author") or feed.get("ownerName") or None,
        feedUrl=feed_url,
        artworkUrl100=feed.get("image") or artwork,
        artworkUrl600=artwork,
        trackCount=feed.get("episodeCount"),
        releaseDate=datetime.fromtimestamp(newest, tz=UTC) if newest else None,
        genres=list(categories.values()) if isinstance(categories, dict) else [],
        itunesId=feed.get("itunesId") or None,
    )


def search_response(feeds: list[dict[str, Any]]) -> SearchResponse:
    """Results for every playable feed, keeping the first of any feeds that share a URL."""
    results: list[PodcastResult] = []
    seen: set[str] = set()
    for feed in feeds:
        result = podcast_result(feed)
        if result is None or result.feedUrl in seen:
            continue
        seen.add(result.feedUrl)
        results.append(result)
    return SearchResponse(resultCount=len(results), results=results)

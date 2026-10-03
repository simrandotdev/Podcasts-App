"""Helpers shared by the tests."""

import httpx

NOW = 1_700_000_000


class FakePodcastIndex:
    """Stands in for api.podcastindex.org. Records each request and answers with `handler`."""

    def __init__(self):
        self.requests: list[httpx.Request] = []
        self.handler = lambda request: httpx.Response(200, json={"status": "true", "feeds": [], "count": 0})

    def respond_with_feeds(self, feeds):
        self.handler = lambda request: httpx.Response(200, json={"status": "true", "feeds": feeds,
                                                                 "count": len(feeds)})

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        return self.handler(request)


def make_feed(feed_id: int, **overrides) -> dict:
    """A Podcast Index search result, with the fields the API uses."""
    feed = {
        "id": feed_id,
        "title": f"Podcast {feed_id}",
        "url": f"https://example.com/{feed_id}.xml",
        "author": f"Author {feed_id}",
        "ownerName": f"Owner {feed_id}",
        "image": f"https://example.com/{feed_id}-image.jpg",
        "artwork": f"https://example.com/{feed_id}-artwork.jpg",
        "episodeCount": 12,
        "newestItemPubdate": NOW,
        "itunesId": 1000 + feed_id,
        "dead": 0,
        "categories": {"102": "Technology", "55": "News"},
    }
    feed.update(overrides)
    return feed

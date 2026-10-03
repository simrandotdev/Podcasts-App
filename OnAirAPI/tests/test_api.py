import hashlib

import httpx

from app.config import Settings, get_settings
from app.main import app, get_podcast_index
from app.podcast_index import PodcastIndexClient, auth_headers
from support import NOW, make_feed


# MARK: - Search


def test_search_returns_itunes_shaped_results(client, podcast_index):
    podcast_index.respond_with_feeds([make_feed(7)])

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 200
    assert response.json() == {
        "resultCount": 1,
        "results": [{
            "wrapperType": "track",
            "kind": "podcast",
            "collectionId": 7,
            "trackId": 7,
            "collectionName": "Podcast 7",
            "trackName": "Podcast 7",
            "artistName": "Author 7",
            "feedUrl": "https://example.com/7.xml",
            "artworkUrl100": "https://example.com/7-image.jpg",
            "artworkUrl600": "https://example.com/7-artwork.jpg",
            "trackCount": 12,
            "releaseDate": "2023-11-14T22:13:20Z",
            "genres": ["Technology", "News"],
            "itunesId": 1007,
        }],
    }


def test_search_sends_term_limit_and_auth_headers(client, podcast_index):
    client.get("/v1/search", params={"term": "  swift talk ", "media": "podcast", "entity": "podcast", "limit": 25})

    request = podcast_index.requests[0]
    assert request.url.path == "/api/1.0/search/byterm"
    assert request.url.params["q"] == "swift talk"
    assert request.url.params["max"] == "25"
    assert request.headers["X-Auth-Key"] == "test-key"
    assert request.headers["X-Auth-Date"] == str(NOW)
    assert request.headers["Authorization"] == hashlib.sha1(f"test-keytest-secret{NOW}".encode()).hexdigest()
    assert request.headers["User-Agent"] == "OnAirAPI/1.0"


def test_search_skips_dead_feeds_feeds_without_url_and_repeated_feeds(client, podcast_index):
    podcast_index.respond_with_feeds([
        make_feed(1),
        make_feed(2, dead=1),
        make_feed(3, url=""),
        make_feed(4, url="https://example.com/1.xml"),
        make_feed(5),
    ])

    results = client.get("/v1/search", params={"term": "news"}).json()["results"]

    assert [result["collectionId"] for result in results] == [1, 5]


def test_search_falls_back_to_owner_and_image(client, podcast_index):
    podcast_index.respond_with_feeds([make_feed(1, author="", artwork="", itunesId=0, categories=None,
                                                newestItemPubdate=None)])

    result = client.get("/v1/search", params={"term": "news"}).json()["results"][0]

    assert result["artistName"] == "Owner 1"
    assert result["artworkUrl600"] == "https://example.com/1-image.jpg"
    assert result["itunesId"] is None
    assert result["genres"] == []
    assert result["releaseDate"] is None


def test_search_without_a_term_is_rejected(client, podcast_index):
    assert client.get("/v1/search").status_code == 422
    assert client.get("/v1/search", params={"term": "   "}).status_code == 422
    assert podcast_index.requests == []


def test_search_for_other_media_is_rejected(client):
    response = client.get("/v1/search", params={"term": "swift", "media": "music"})

    assert response.status_code == 422


def test_search_limit_outside_1_to_200_is_rejected(client):
    assert client.get("/v1/search", params={"term": "swift", "limit": 0}).status_code == 422
    assert client.get("/v1/search", params={"term": "swift", "limit": 201}).status_code == 422


# MARK: - Trending


def test_trending_returns_results_and_sends_filters(client, podcast_index):
    trending_feed = make_feed(9)
    del trending_feed["episodeCount"], trending_feed["newestItemPubdate"], trending_feed["ownerName"]
    trending_feed["newestItemPublishTime"] = NOW
    podcast_index.respond_with_feeds([trending_feed])

    response = client.get("/v1/podcasts/trending", params={"limit": 10, "lang": "en", "category": "News,Comedy"})

    assert response.status_code == 200
    result = response.json()["results"][0]
    assert result["collectionId"] == 9
    assert result["trackCount"] is None
    assert result["releaseDate"] == "2023-11-14T22:13:20Z"
    request = podcast_index.requests[0]
    assert request.url.path == "/api/1.0/podcasts/trending"
    assert dict(request.url.params) == {"max": "10", "lang": "en", "cat": "News,Comedy"}


def test_trending_without_filters_sends_only_the_limit(client, podcast_index):
    client.get("/v1/podcasts/trending")

    assert dict(podcast_index.requests[0].url.params) == {"max": "50"}


# MARK: - Failures


def test_missing_credentials_return_503_without_calling_podcast_index(client, podcast_index):
    settings = Settings(_env_file=None, podcastindex_api_key="test-key", podcastindex_api_secret="")
    http = httpx.AsyncClient(transport=httpx.MockTransport(podcast_index))
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_podcast_index] = lambda: PodcastIndexClient(http, settings)

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 503
    assert response.json() == {"detail": "The Podcast Index API key and secret aren't configured."}
    assert podcast_index.requests == []


def test_rejected_credentials_return_502(client, podcast_index):
    podcast_index.handler = lambda request: httpx.Response(401, text="Authorization header is invalid")

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 502
    assert response.json() == {"detail": "Podcast Index rejected the API credentials."}


def test_upstream_server_error_returns_502(client, podcast_index):
    podcast_index.handler = lambda request: httpx.Response(500)

    response = client.get("/v1/podcasts/trending")

    assert response.status_code == 502
    assert response.json() == {"detail": "Podcast Index returned HTTP 500."}


def test_upstream_failure_status_returns_502_with_its_description(client, podcast_index):
    podcast_index.handler = lambda request: httpx.Response(200, json={"status": "false",
                                                                      "description": "Invalid parameters"})

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 502
    assert response.json() == {"detail": "Invalid parameters"}


def test_unreadable_upstream_response_returns_502(client, podcast_index):
    podcast_index.handler = lambda request: httpx.Response(200, text="<html>maintenance</html>")

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 502
    assert response.json() == {"detail": "Podcast Index returned an unreadable response."}


def test_upstream_timeout_returns_504(client, podcast_index):
    def time_out(request):
        raise httpx.ReadTimeout("timed out", request=request)
    podcast_index.handler = time_out

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 504
    assert response.json() == {"detail": "Podcast Index didn't respond in time."}


def test_unreachable_upstream_returns_502(client, podcast_index):
    def refuse(request):
        raise httpx.ConnectError("connection refused", request=request)
    podcast_index.handler = refuse

    response = client.get("/v1/search", params={"term": "swift"})

    assert response.status_code == 502
    assert response.json() == {"detail": "Couldn't reach Podcast Index."}


# MARK: - Other


def test_health_reports_ok(client, podcast_index):
    response = client.get("/health")

    assert response.json() == {"status": "ok"}
    assert podcast_index.requests == []


def test_auth_headers_hash_key_secret_and_whole_seconds():
    headers = auth_headers("key", "secret", "Agent/1", 1_700_000_000.9)

    assert headers == {
        "User-Agent": "Agent/1",
        "X-Auth-Key": "key",
        "X-Auth-Date": "1700000000",
        "Authorization": hashlib.sha1(b"keysecret1700000000").hexdigest(),
    }

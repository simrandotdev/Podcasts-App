# On Air API

A small FastAPI service that replaces the iTunes Search API in the On Air apps with [Podcast Index](https://podcastindex.org). It keeps the Podcast Index secret on the server, so the apps never ship it.

The iOS app uses iTunes only to search for podcasts. Episodes come from each podcast's RSS feed. This service provides that search in the same response shape, plus trending podcasts for the Home screen.

## Endpoints

| Endpoint | Replaces | Podcast Index call |
| --- | --- | --- |
| `GET /v1/search?term=&limit=50` | `https://itunes.apple.com/search?media=podcast&entity=podcast` | `/search/byterm` |
| `GET /v1/podcasts/trending?limit=50&lang=&category=` | The Home list, which searches iTunes for "podcasts" | `/podcasts/trending` |
| `GET /health` | | None |

Interactive documentation is at `/docs` while the server runs.

- **`/v1/search`** takes `term` (required) and `limit` (1–200, default 50). It also accepts `media=podcast` and `entity=podcast`, so the app's current query string works unchanged.
- **`/v1/podcasts/trending`** takes `limit`, an optional `lang` such as `en`, and an optional `category` with category names or IDs separated by commas.

Both return the iTunes response shape:

```json
{
  "resultCount": 1,
  "results": [
    {
      "wrapperType": "track",
      "kind": "podcast",
      "collectionId": 920666,
      "trackId": 920666,
      "collectionName": "Swift by Sundell",
      "trackName": "Swift by Sundell",
      "artistName": "John Sundell",
      "feedUrl": "https://example.com/feed.xml",
      "artworkUrl100": "https://example.com/image.jpg",
      "artworkUrl600": "https://example.com/artwork.jpg",
      "trackCount": 120,
      "releaseDate": "2024-05-01T08:00:00Z",
      "genres": ["Technology"],
      "itunesId": 1219454367
    }
  ]
}
```

### How Results Are Mapped

| Result field | Podcast Index feed field |
| --- | --- |
| `collectionId`, `trackId` | `id`, the Podcast Index feed ID |
| `collectionName`, `trackName` | `title` |
| `artistName` | `author`, or `ownerName` |
| `feedUrl` | `url` |
| `artworkUrl600` | `artwork`, or `image` |
| `artworkUrl100` | `image`, or `artwork` |
| `trackCount` | `episodeCount`. Trending results don't include it |
| `releaseDate` | `newestItemPubdate`, or `newestItemPublishTime` for trending |
| `genres` | The names in `categories` |
| `itunesId` | `itunesId`, when Podcast Index knows it |

Feeds that Podcast Index marks as dead, and feeds without a URL, are left out. When several feeds share a URL, only the first is kept.

### Errors

Errors use FastAPI's `{"detail": "..."}` format.

| Status | Cause |
| --- | --- |
| 422 | Invalid parameters, such as a missing or blank `term` |
| 502 | Podcast Index couldn't be reached, rejected the credentials, or returned an error |
| 503 | The API key or secret isn't configured |
| 504 | Podcast Index didn't respond in time |

## Set Up

The service needs Python 3.11 or later and [uv](https://docs.astral.sh/uv/).

1. Create a free API key and secret at <https://api.podcastindex.org>.
2. Copy `.env.example` to `.env` and fill in `PODCASTINDEX_API_KEY` and `PODCASTINDEX_API_SECRET`. Git ignores `.env`. You can also set the same names as environment variables.
3. Install the dependencies:

   ```sh
   uv sync
   ```

## Run

```sh
uv run uvicorn app.main:app --reload
```

Then try <http://127.0.0.1:8000/v1/search?term=swift> or open <http://127.0.0.1:8000/docs>.

To reach the server from the iOS Simulator, use `http://127.0.0.1:8000`. To reach it from a device on the same network, start it with `--host 0.0.0.0` and use your Mac's IP address.

## Test

```sh
uv run pytest
```

The tests replace Podcast Index with an `httpx.MockTransport`, so they never use the network or real credentials.

## Use It from the iOS App

In `OnAir-iOS`, `APIService.fetchPodcastsAsync(searchText:)` builds the iTunes URL. Point it at this service's `/v1/search` instead. The query parameters and the response format stay the same. To use trending podcasts for the Home list, call `/v1/podcasts/trending` where `PodcastsManager.fetchPodcasts()` searches for "podcasts" today.

## Project Layout

| Path | Contents |
| --- | --- |
| `app/main.py` | The FastAPI app and its routes |
| `app/podcast_index.py` | The Podcast Index client, including request signing |
| `app/schemas.py` | The iTunes-style response models and the mapping from Podcast Index feeds |
| `app/config.py` | Settings, read from the environment or `.env` |
| `tests/` | Tests, with a fake Podcast Index |

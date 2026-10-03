# Loading Podcasts and Feeds

Find podcasts through the On Air API, and turn RSS feeds into episodes with FeedKit.

## Overview

`APIService` makes every network request for podcast data. It has three jobs: searching for podcasts, listing trending podcasts for the Home tab, and downloading and parsing a podcast's RSS feed. All of them return domain models, `Podcast` and `Episode`, to the repositories.

![Two pipelines. Searching: APIService's fetchPodcastsAsync sends a GET request to the On Air API's /v1/search, or to itunes.apple.com/search when the API isn't configured. The results are decoded while skipping entries without a feed URL and repeated feeds, and the result is an array of Podcast identified by rssFeedUrl. Loading episodes: APIService's fetchEpisodesAsync downloads the podcast's RSS feed over HTTP or HTTPS, FeedKit parses it and converts it with RSSFeed.toEpisodes, and the result is an array of Episode identified by streamUrl.](networking)

`APIService.shared` uses a `URLSession` that times out a request after 30 seconds and a whole resource after 60. Its initializer also accepts a session and an On Air API address, which tests use to stub the network.

### Choose Where Podcasts Come From

Podcasts come from the On Air API, a FastAPI service in the repository's `OnAirAPI` folder that searches [Podcast Index](https://podcastindex.org). The service holds the Podcast Index credentials, so the app never ships them.

The app finds the service through the `OnAirAPIBaseURL` key in `Info.plist`, which the `ONAIR_API_BASE_URL` build setting fills in for each build configuration:

| Configuration | `ONAIR_API_BASE_URL` | Podcasts come from |
| --- | --- | --- |
| Debug | `https://onair-api.onrender.com` | The On Air API, deployed on Render |
| Release | `https://onair-api.onrender.com` | The On Air API, deployed on Render |

The service is deployed on Render from the repository's `render.yaml`. It runs on Render's free plan, which stops the service after 15 minutes without traffic. The first request afterwards waits while it starts, and can take longer than the app's 30-second request timeout. The Retry button then loads the list.

When the value is empty, `APIService` falls back to the iTunes Search API. The On Air API returns the iTunes response format, so both sources decode the same way.

> Tip: To try changes to the service before deploying them, run it on the Mac and set the Debug value to `http://127.0.0.1:8000`. That address reaches the Mac from the iOS Simulator, but not from a device. For a device, run the service with `--host 0.0.0.0` and use the Mac's network address.

### Search for Podcasts

`fetchPodcastsAsync(searchText:)` sends a `GET` request to one of these:

| Source | Request |
| --- | --- |
| The On Air API | `/v1/search` with `term` and `limit=50` |
| The iTunes Search API | `https://itunes.apple.com/search` with `term`, `media=podcast`, `entity=podcast`, and `limit=50` |

### Load Trending Podcasts

`fetchTrendingPodcastsAsync()` supplies the Home tab's station list. It requests `/v1/podcasts/trending?limit=50` from the On Air API. Without the API, it searches iTunes for `APIService.iTunesHomeSearchTerm`, which is "podcasts".

### Decode the Results

Both requests decode each result and map it to a `Podcast`:

| `Podcast` | Result field |
| --- | --- |
| `recordId` | `itunesId` when the On Air API provides it, or `collectionId` |
| `title` | `collectionName` |
| `author` | `artistName` |
| `image` | `artworkUrl600`, or `artworkUrl100` |
| `totalEpisodes` | `trackCount` |
| `rssFeedUrl` | `feedUrl` |

In On Air API results, `collectionId` is the Podcast Index feed ID. Preferring the iTunes ID keeps a podcast's `recordId` the same as when the app searched iTunes.

Results without a feed URL can't be played, so `APIService` skips them. It also drops repeated feeds, because the feed URL identifies a podcast everywhere in the app.

### Load a Podcast's Episodes

`fetchEpisodesAsync(forPodcast:)` downloads the feed at the podcast's `rssFeedUrl` and parses it with FeedKit's `FeedParser`. The app supports RSS feeds only. An Atom or JSON feed fails with `APIError.failedToParseRss`.

`RSSFeed.toEpisodes(podcastFeedUrl:)` converts each feed item to an `Episode`:

| `Episode` | Feed item |
| --- | --- |
| `streamUrl` | The enclosure's URL |
| `title` | `title` |
| `pubDate` | `pubDate`, or the time of parsing when the item has none |
| `description` | `itunes:subtitle`, or `description` |
| `subtitle` | `itunes:subtitle` |
| `author` | `itunes:author` |
| `imageUrl` | The item's `itunes:image`, or the channel's |
| `podcastFeedUrl` | The feed URL that was requested |

> Note: Because an undated item gets the time of parsing, its date changes on every load. That's why new-episode tracking also requires an episode's stream URL to be unfamiliar. See <doc:Tracking-New-Episodes>.

### Handle Errors

`APIService` checks for cancellation after each download, so a search that a newer one replaced stops early. It throws `APIError` for anything it can't use:

| Case | Cause |
| --- | --- |
| `invalidRequest` | The URL couldn't be built, or the response wasn't HTTP |
| `httpStatus(_:)` | The server returned a status outside 200–299 |
| `failedToParseRss` | The feed isn't a supported RSS feed |
| `failedToParseJSON` | The search response couldn't be read |

Each case has a readable `errorDescription`, which view models include in the error messages they show.

### Allow Plain HTTP

Many podcast feeds and audio files are still served over plain HTTP, and so is the On Air API when it runs on the Mac. `Info.plist` sets `NSAllowsArbitraryLoads` so the app can load them.

### Load Artwork

`PodcastArtwork` loads images with `AsyncImage`, which uses `URLSession.shared`. `PodcastsApp` enlarges `URLCache.shared` at launch, so artwork stays cached while the user scrolls. Settings can clear that cache.

## See Also

- <doc:Discovering-Podcasts>
- <doc:Viewing-a-Podcast>
- <doc:Testing-the-App>

# Loading Podcasts and Feeds

Search the iTunes catalog, and turn RSS feeds into episodes with FeedKit.

## Overview

`APIService` makes every network request for podcast data. It has two jobs: searching the iTunes Search API for podcasts, and downloading and parsing a podcast's RSS feed. Both return domain models, `Podcast` and `Episode`, to the repositories.

![Two pipelines. Searching: APIService's fetchPodcastsAsync sends a GET request to itunes.apple.com/search, the results are decoded while skipping entries without a feed URL and repeated feeds, and the result is an array of Podcast identified by rssFeedUrl. Loading episodes: APIService's fetchEpisodesAsync downloads the podcast's RSS feed over HTTP or HTTPS, FeedKit parses it and converts it with RSSFeed.toEpisodes, and the result is an array of Episode identified by streamUrl.](networking)

`APIService.shared` uses a `URLSession` that times out a request after 30 seconds and a whole resource after 60. Its initializer also accepts a session, which tests use to stub the network.

### Search the iTunes Catalog

`fetchPodcastsAsync(searchText:)` sends a `GET` request to `https://itunes.apple.com/search` with these parameters:

| Parameter | Value |
| --- | --- |
| `term` | The search text |
| `media` | `podcast` |
| `entity` | `podcast` |
| `limit` | `50` |

It decodes each result and maps it to a `Podcast`:

| `Podcast` | iTunes result |
| --- | --- |
| `recordId` | `collectionId` |
| `title` | `collectionName` |
| `author` | `artistName` |
| `image` | `artworkUrl600`, or `artworkUrl100` |
| `totalEpisodes` | `trackCount` |
| `rssFeedUrl` | `feedUrl` |

Results without a feed URL can't be played, so it skips them. It also drops repeated feeds, because the feed URL identifies a podcast everywhere in the app.

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

Many podcast feeds and audio files are still served over plain HTTP. `Info.plist` sets `NSAllowsArbitraryLoads` so the app can load them.

### Load Artwork

`PodcastArtwork` loads images with `AsyncImage`, which uses `URLSession.shared`. `PodcastsApp` enlarges `URLCache.shared` at launch, so artwork stays cached while the user scrolls. Settings can clear that cache.

## See Also

- <doc:Discovering-Podcasts>
- <doc:Viewing-a-Podcast>
- <doc:Testing-the-App>
